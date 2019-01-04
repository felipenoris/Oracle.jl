
function Stmt(connection::Connection, sql::String; scrollable::Bool=false, tag::String="")
    stmt_handle_ref = Ref{Ptr{Cvoid}}()
    dpi_result = dpiConn_prepareStmt(connection.handle, scrollable, sql, tag, stmt_handle_ref)
    error_check(connection.context, dpi_result)
    return Stmt(connection, stmt_handle_ref[])
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
    return num_query_columns_ref[]
end

function num_query_columns(stmt::Stmt) :: UInt32
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
    return (found, buffer_row_index_ref[])
end

function is_null(val::DataValue)
#=
    # DataValue.dpi_data::dpiData

    if val.dpi_data.is_null == 0
        return false
    elseif val.dpi_data.is_null == 1
        return true
    else
        error("Unexpected value for dpiData.is_null field: $(val.dpi_data.is_null)")
    end
=#

    is_null_as_cint = dpiData_isNull(val.dpi_data_handle)
    if is_null_as_cint == 0
        return false
    elseif is_null_as_cint == 1
        return true
    else
        error("Unexpected value for dpiData.is_null field: $(Int(is_null_as_cint))")
    end
end

function query_value(stmt::Stmt, column_index::UInt32) :: DataValue
    native_type_ref = Ref{dpiNativeTypeNum}()
    data_handle_ref = Ref{Ptr{dpiData}}()
    dpi_result = dpiStmt_getQueryValue(stmt.handle, column_index, native_type_ref, data_handle_ref)
    error_check(stmt.connection.context, dpi_result)
    return DataValue(native_type_ref[], data_handle_ref[])
end
query_value(stmt::Stmt, column_index::Integer) = query_value(stmt, UInt32(column_index))
