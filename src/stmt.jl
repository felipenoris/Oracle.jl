
function Stmt(connection::Connection, sql::String; scrollable::Bool=false, tag::String="")
    stmt_handle_ref = Ref{Ptr{Cvoid}}()
    dpi_result = dpiConn_prepareStmt(connection.handle, scrollable, sql, tag, stmt_handle_ref)
    error_check(connection.context, dpi_result)
    return Stmt(connection, stmt_handle_ref[], scrollable)
end

"""
    execute!(stmt::Stmt; exec_mode::dpiExecMode=DPI_MODE_EXEC_DEFAULT) :: UInt32

Returns the number of columns which are being queried.
If the statement does not refer to a query, the value is set to 0.
"""
function execute!(stmt::Stmt; exec_mode::dpiExecMode=DPI_MODE_EXEC_DEFAULT) :: UInt32
    num_query_columns_ref = Ref{UInt32}(0)
    dpi_result = dpiStmt_execute(stmt.handle, exec_mode, num_query_columns_ref)
    error_check(stmt.connection.context, dpi_result)
    stmt.executed = true
    return num_query_columns_ref[]
end

function close!(stmt::Stmt; tag::String="")
    dpi_result = dpiStmt_close(stmt.handle, tag=tag)
    error_check(stmt.connection.context, dpi_result)
    nothing
end

function num_query_columns(stmt::Stmt) :: UInt32
    @assert stmt.executed "Cannot query number of query columns on a non-executed statement."
    num_query_columns_ref = Ref{UInt32}(0)
    dpi_result = dpiStmt_getNumQueryColumns(stmt.handle, num_query_columns_ref)
    error_check(stmt.connection.context, dpi_result)
    return num_query_columns_ref[]
end

function dpiQueryInfo(stmt::Stmt, column_index::UInt32)
    query_info_ref = Ref{dpiQueryInfo}()
    dpi_result = dpiStmt_getQueryInfo(stmt.handle, column_index, query_info_ref)
    error_check(stmt.connection.context, dpi_result)
    query_info_ref[]
end

dpiQueryInfo(stmt::Stmt, column_index::Integer) = dpiQueryInfo(stmt, UInt32(column_index))
column_name(query_info::dpiQueryInfo) = unsafe_string(query_info.name, query_info.name_length)

function dpiStmtInfo(stmt::Stmt)
    stmt_info_ref = Ref{dpiStmtInfo}()
    dpi_result = dpiStmt_getInfo(stmt.handle, stmt_info_ref)
    error_check(stmt.connection.context, dpi_result)
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

function fetch_rows!(stmt::Stmt, max_rows::Integer=DPI_DEFAULT_FETCH_ARRAY_SIZE) :: FetchRowsResult
    buffer_row_index_ref = Ref{UInt32}()
    num_rows_fetched_ref = Ref{UInt32}()
    more_rows_ref = Ref{Int32}()

    dpi_result = dpiStmt_fetchRows(stmt.handle, UInt32(max_rows), buffer_row_index_ref, num_rows_fetched_ref, more_rows_ref)
    error_check(stmt.connection.context, dpi_result)
    return FetchRowsResult(buffer_row_index_ref[], num_rows_fetched_ref[], more_rows_ref[])
end

function query_value(stmt::Stmt, column_index::UInt32) :: NativeValue
    native_type_ref = Ref{dpiNativeTypeNum}()
    data_handle_ref = Ref{Ptr{dpiData}}()
    dpi_result = dpiStmt_getQueryValue(stmt.handle, column_index, native_type_ref, data_handle_ref)
    error_check(stmt.connection.context, dpi_result)
    return NativeValue(native_type_ref[], data_handle_ref[])
end
query_value(stmt::Stmt, column_index::Integer) = query_value(stmt, UInt32(column_index))

function is_query(stmt::Stmt) :: Bool
    stmt_info = dpiStmtInfo(stmt)
    if stmt_info.is_query == 1
        return true
    elseif stmt_info.is_query == 0
        return false
    else
        error("Invalid value for dpiStmtInfo.is_query: ", stmt_info.is_query)
    end
end

@inline function _bind_aux!(stmt::Stmt, value::T, name::String, native_type::dpiNativeTypeNum, set_data_function::F) where {T, F<:Function}
    dpi_data_ref = Ref{dpiData}()
    set_data_function(dpi_data_ref, value)
    dpi_result = dpiStmt_bindValueByName(stmt.handle, name, native_type, dpi_data_ref)
    error_check(stmt.connection.context, dpi_result)
    nothing
end

bind!(stmt::Stmt, value, name::Symbol) = bind!(stmt, value, String(name))
bind!(stmt::Stmt, value::String, name::String) = _bind_aux!(stmt, value, name, DPI_NATIVE_TYPE_BYTES, dpiData_setBytes)
bind!(stmt::Stmt, value::Float64, name::String) = _bind_aux!(stmt, value, name, DPI_NATIVE_TYPE_DOUBLE, dpiData_setDouble)
bind!(stmt::Stmt, value::Int64, name::String) = _bind_aux!(stmt, value, name, DPI_NATIVE_TYPE_INT64, dpiData_setInt64)
bind!(stmt::Stmt, value::Date, name::String) = _bind_aux!(stmt, dpiTimestamp(value), name, DPI_NATIVE_TYPE_TIMESTAMP, dpiData_setTimestamp)
bind!(stmt::Stmt, value::Missing, name::Symbol, native_type) = bind!(stmt, value, String(name), native_type)

function bind!(stmt::Stmt, value::Missing, name::String, native_type::dpiNativeTypeNum)
    @assert ismissing(value) # sanity check
    dpi_data_ref = Ref{dpiData}()
    dpiData_setNull(dpi_data_ref)
    dpi_result = dpiStmt_bindValueByName(stmt.handle, name, native_type, dpi_data_ref) # native type is not examined since the value is passed as a NULL
    error_check(stmt.connection.context, dpi_result)
    nothing
end

function bind!(stmt::Stmt, value::Missing, name::String, julia_type::Type{T}) where {T}
    bind!(stmt, value, name, dpiNativeTypeNum(julia_type))
end

Base.setindex!(stmt::Stmt, value, key) = bind!(stmt, value, key)
Base.setindex!(stmt::Stmt, value, key, type_information) = bind!(stmt, value, key, type_information)
