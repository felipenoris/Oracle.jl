
function Stmt(connection::Connection, sql::String; scrollable::Bool=false, tag::String="")
    stmt_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_prepareStmt(connection.handle, scrollable, sql, tag, stmt_handle_ref)
    error_check(connection.context, result)
    return Stmt(connection, stmt_handle_ref[], scrollable)
end

"""
    execute!(stmt::Stmt; exec_mode::dpiExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32

Returns the number of columns which are being queried.
If the statement does not refer to a query, the value is set to 0.
"""
function execute!(stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    num_query_columns_ref = Ref{UInt32}(0)
    result = dpiStmt_execute(stmt.handle, exec_mode, num_query_columns_ref)
    error_check(context(stmt), result)
    return num_query_columns_ref[]
end

function close!(stmt::Stmt; tag::String="")
    result = dpiStmt_close(stmt.handle, tag=tag)
    error_check(context(stmt), result)
    nothing
end

function num_query_columns(stmt::Stmt) :: UInt32
    num_query_columns_ref = Ref{UInt32}(0)
    result = dpiStmt_getNumQueryColumns(stmt.handle, num_query_columns_ref)
    error_check(context(stmt), result)
    return num_query_columns_ref[]
end

function OraQueryInfo(stmt::Stmt, column_index::UInt32)
    query_info_ref = Ref{OraQueryInfo}()
    result = dpiStmt_getQueryInfo(stmt.handle, column_index, query_info_ref)
    error_check(context(stmt), result)
    return query_info_ref[]
end

OraQueryInfo(stmt::Stmt, column_index::Integer) = OraQueryInfo(stmt, UInt32(column_index))
column_name(query_info::OraQueryInfo) = unsafe_string(query_info.name, query_info.name_length)

function OraStmtInfo(stmt::Stmt)
    stmt_info_ref = Ref{OraStmtInfo}()
    result = dpiStmt_getInfo(stmt.handle, stmt_info_ref)
    error_check(context(stmt), result)
    return stmt_info_ref[]
end

"""
    fetch!(stmt::Stmt)

Fetches a single row from the statement.
"""
function fetch!(stmt::Stmt)
    found_ref = Ref{Int32}(0)
    buffer_row_index_ref = Ref{UInt32}(0) # This index is used as the array position for getting values from the variables that have been defined for the statement.
    dpiStmt_fetch(stmt.handle, found_ref, buffer_row_index_ref)

    local found::Bool = false
    if found_ref[] != 0
        found = true
    end
    return FetchResult(found, buffer_row_index_ref[])
end

function fetch_rows!(stmt::Stmt, max_rows::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE) :: FetchRowsResult
    buffer_row_index_ref = Ref{UInt32}()
    num_rows_fetched_ref = Ref{UInt32}()
    more_rows_ref = Ref{Int32}()

    result = dpiStmt_fetchRows(stmt.handle, UInt32(max_rows), buffer_row_index_ref, num_rows_fetched_ref, more_rows_ref)
    error_check(context(stmt), result)
    return FetchRowsResult(buffer_row_index_ref[], num_rows_fetched_ref[], more_rows_ref[])
end

function query_value(stmt::Stmt, column_index::UInt32) :: NativeValue
    native_type_ref = Ref{OraNativeTypeNum}()
    data_handle_ref = Ref{Ptr{OraData}}()
    result = dpiStmt_getQueryValue(stmt.handle, column_index, native_type_ref, data_handle_ref)
    error_check(context(stmt), result)
    return NativeValue(native_type_ref[], data_handle_ref[])
end
query_value(stmt::Stmt, column_index::Integer) = query_value(stmt, UInt32(column_index))

function is_query(stmt::Stmt) :: Bool
    stmt_info = OraStmtInfo(stmt)
    if stmt_info.is_query == 1
        return true
    elseif stmt_info.is_query == 0
        return false
    else
        error("Invalid value for OraStmtInfo.is_query: ", stmt_info.is_query)
    end
end

@inline function _bind_aux!(stmt::Stmt, value::T, name::String, native_type::OraNativeTypeNum, set_data_function::F) where {T, F<:Function}
    data_ref = Ref{OraData}()
    set_data_function(data_ref, value)
    result = dpiStmt_bindValueByName(stmt.handle, name, native_type, data_ref)
    error_check(context(stmt), result)
    nothing
end

bind!(stmt::Stmt, value, name::Symbol) = bind!(stmt, value, String(name))
bind!(stmt::Stmt, value::String, name::String) = _bind_aux!(stmt, value, name, ORA_NATIVE_TYPE_BYTES, dpiData_setBytes)
bind!(stmt::Stmt, value::Float64, name::String) = _bind_aux!(stmt, value, name, ORA_NATIVE_TYPE_DOUBLE, dpiData_setDouble)
bind!(stmt::Stmt, value::Int64, name::String) = _bind_aux!(stmt, value, name, ORA_NATIVE_TYPE_INT64, dpiData_setInt64)
bind!(stmt::Stmt, value::Missing, name::Symbol, native_type) = bind!(stmt, value, String(name), native_type)

function bind!(stmt::Stmt, value::T, name::String) where {T<:Dates.TimeType}
    _bind_aux!(stmt, OraTimestamp(value), name, ORA_NATIVE_TYPE_TIMESTAMP, dpiData_setTimestamp)
end

function bind!(stmt::Stmt, value::Missing, name::String, native_type::OraNativeTypeNum)
    @assert ismissing(value) # sanity check
    data_ref = Ref{OraData}()
    dpiData_setNull(data_ref)
    result = dpiStmt_bindValueByName(stmt.handle, name, native_type, data_ref) # native type is not examined since the value is passed as a NULL
    error_check(context(stmt), result)
    nothing
end

function bind!(stmt::Stmt, value::Missing, name::String, julia_type::Type{T}) where {T}
    bind!(stmt, value, name, OraNativeTypeNum(julia_type))
end

Base.setindex!(stmt::Stmt, value, key) = bind!(stmt, value, key)
Base.setindex!(stmt::Stmt, value, key, type_information) = bind!(stmt, value, key, type_information)
