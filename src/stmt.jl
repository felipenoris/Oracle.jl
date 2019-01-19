
function Stmt(connection::Connection, sql::String; scrollable::Bool=false, tag::String="")
    stmt_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_prepareStmt(connection.handle, scrollable, sql, tag, stmt_handle_ref)
    error_check(connection.context, result)
    return Stmt(connection, stmt_handle_ref[], scrollable)
end

function execute!(stmt::Stmt{StmtQueryType}; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: QueryExecutionResult
    num_columns = raw_execute!(stmt, exec_mode)
    return QueryExecutionResult(stmt, num_columns)
end

function execute!(stmt::Stmt{StmtDMLType}; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: DMLExecutionResult
    num_columns = raw_execute!(stmt, exec_mode)
    @assert num_columns == 0 "num_columns should be zero for non-query statements."

    row_count_ref = Ref{UInt64}()
    result = dpiStmt_getRowCount(stmt.handle, row_count_ref)
    error_check(context(stmt), result)

    return DMLExecutionResult(stmt, row_count_ref[])
end

function execute!(stmt::Stmt{StmtOtherType}; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: GenericStmtExecutionResult
    num_columns = raw_execute!(stmt, exec_mode)
    return GenericStmtExecutionResult(stmt, num_columns)
end

function execute!(connection::Connection, sql::String; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT)
    stmt = Stmt(connection, sql; scrollable=scrollable, tag=tag)
    execute_result = execute!(stmt, exec_mode=exec_mode)
    close!(stmt)
    return execute_result
end

"""
    raw_execute!(stmt::Stmt; exec_mode::dpiExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32

Returns the number of columns which are being queried.
If the statement does not refer to a query, the value is set to 0.
"""
function raw_execute!(stmt::Stmt, exec_mode::OraExecMode) :: UInt32
    num_columns_ref = Ref{UInt32}(0)
    result = dpiStmt_execute(stmt.handle, exec_mode, num_columns_ref)
    error_check(context(stmt), result)
    return num_columns_ref[]
end

function close!(stmt::Stmt; tag::String="")
    result = dpiStmt_close(stmt.handle, tag=tag)
    error_check(context(stmt), result)
    nothing
end

function num_columns(stmt::Stmt) :: UInt32
    num_columns_ref = Ref{UInt32}(0)
    result = dpiStmt_getNumQueryColumns(stmt.handle, num_columns_ref)
    error_check(context(stmt), result)
    return num_columns_ref[]
end

function OraQueryInfo(stmt::Stmt, column_index::UInt32)
    query_info_ref = Ref{OraQueryInfo}()
    result = dpiStmt_getQueryInfo(stmt.handle, column_index, query_info_ref)
    error_check(context(stmt), result)
    return query_info_ref[]
end

OraQueryInfo(stmt::Stmt, column_index::Integer) = OraQueryInfo(stmt, UInt32(column_index))
column_name(query_info::OraQueryInfo) = unsafe_string(query_info.name, query_info.name_length)

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

function check_bind_bounds(stmt::Stmt, pos::Integer)
    @assert pos > 0 && pos <= stmt.bind_count "Bind position $pos out of bounds."
    nothing
end

function check_bind_bounds(stmt::Stmt, name::String)
    name_upper = uppercase(name)
    @assert haskey(stmt.bind_names_index, name_upper) "Bind name $name_upper not found in statement."
end

check_bind_bounds(stmt::Stmt, name::Symbol) = check_bind_bounds(stmt, string(name))

@static if VERSION < v"0.7-"
    # implement bind! without using @generated function for Julia v0.6

    Base.setindex!(stmt::Stmt, value, key, type_information) = bind!(stmt, value, key, type_information)
    Base.setindex!(stmt::Stmt, value, key) = bind!(stmt, value, key)

    function _bind_aux!(stmt::Stmt, value::T, name::String, native_type::OraNativeTypeNum, set_data_function::F) where {T, F<:Function}
        check_bind_bounds(stmt, name)
        data_ref = Ref{OraData}()
        set_data_function(data_ref, value)
        result = dpiStmt_bindValueByName(stmt.handle, name, native_type, data_ref)
        error_check(context(stmt), result)
        nothing
    end

    function _bind_aux!(stmt::Stmt, value::T, pos::Integer, native_type::OraNativeTypeNum, set_data_function::F) where {T, F<:Function}
        check_bind_bounds(stmt, pos)
        data_ref = Ref{OraData}()
        set_data_function(data_ref, value)
        result = dpiStmt_bindValueByPos(stmt.handle, UInt32(pos), native_type, data_ref)
        error_check(context(stmt), result)
        nothing
    end

    bind!(stmt::Stmt, value, name::Symbol) = bind!(stmt, value, String(name))

    bind!(stmt::Stmt, value::String, name::Union{Integer, String}) = _bind_aux!(stmt, value, name, ORA_NATIVE_TYPE_BYTES, dpiData_setBytes)
    bind!(stmt::Stmt, value::Float64, name::Union{Integer, String}) = _bind_aux!(stmt, value, name, ORA_NATIVE_TYPE_DOUBLE, dpiData_setDouble)
    bind!(stmt::Stmt, value::Int64, name::Union{Integer, String}) = _bind_aux!(stmt, value, name, ORA_NATIVE_TYPE_INT64, dpiData_setInt64)
    bind!(stmt::Stmt, value::Missing, name::Symbol, native_type) = bind!(stmt, value, String(name), native_type)

    function bind!(stmt::Stmt, value::T, name::Union{Integer, String}) where {T<:Dates.TimeType}
        _bind_aux!(stmt, OraTimestamp(value), name, ORA_NATIVE_TYPE_TIMESTAMP, dpiData_setTimestamp)
    end

    function bind!(stmt::Stmt, value::Missing, name::String, native_type::OraNativeTypeNum)
        check_bind_bounds(stmt, name)
        data_ref = Ref{OraData}()
        dpiData_setNull(data_ref)
        result = dpiStmt_bindValueByName(stmt.handle, name, native_type, data_ref) # native type is not examined since the value is passed as a NULL
        error_check(context(stmt), result)
        nothing
    end

    function bind!(stmt::Stmt, value::Missing, pos::Integer, native_type::OraNativeTypeNum)
        check_bind_bounds(stmt, pos)
        data_ref = Ref{OraData}()
        dpiData_setNull(data_ref)
        result = dpiStmt_bindValueByPos(stmt.handle, UInt32(pos), native_type, data_ref) # native type is not examined since the value is passed as a NULL
        error_check(context(stmt), result)
        nothing
    end

    function bind!(stmt::Stmt, value::Missing, name::Union{Integer, String}, julia_type::Type{T}) where {T}
        bind!(stmt, value, name, OraNativeTypeNum(julia_type))
    end
else
    # for Julia v1.0, use @generated functions to implement bind!

    Base.setindex!(stmt::Stmt, value, key, type_information=nothing) = bind!(stmt, value, key, type_information)

    @generated function bind!(stmt::Stmt, value, position_or_name::Union{Integer, String, Symbol}, type_information::Union{Nothing, OraNativeTypeNum, Type{T}}=nothing) where T

        if type_information <: Type{T}
            # supports Julia native type parameter, as in `stmt[:flt, Float64] = missing`
            return quote
                bind!(stmt, value, position_or_name, OraNativeTypeNum(type_information))
            end
        end

        if value <: Dates.TimeType
            # supports a value as Julia native types Date or DateTime, as in `stmt[:dt] = Date(2018,12,31)`
            return quote
                bind!(stmt, OraTimestamp(value), position_or_name, type_information)
            end
        end

        if position_or_name <: Symbol
            # all symbols are converted to strings, because that's what ODPI-C expects to receive
            return quote
                bind!(stmt, value, string(position_or_name), type_information)
            end
        end

        if position_or_name <: Integer && !(position_or_name <: UInt32)
            # all position integers are converted to UInt32, because that's what ODPI-C expects to receive
            return quote
                bind!(stmt, value, UInt32(position_or_name), type_information)
            end
        end

        # dpiStmt_bindValueByName is used for strings, dpiStmt_bindValueByPos for position.
        if position_or_name <: UInt32
            dpi_bind_function_name = :dpiStmt_bindValueByPos
        elseif position_or_name <: String
            dpi_bind_function_name = :dpiStmt_bindValueByName
        else
            error("Unexpected type for argument position_or_name: $position_or_name.")
        end

        if value <: Missing
            # if the user passes a missing value, it must provide type information, as in `stmt[:str, String] = missing`
            @assert !(type_information <: Nothing) "Binding a missing value requires type information argument."

            return quote
                check_bind_bounds(stmt, position_or_name)
                data_ref = Ref{OraData}()
                dpiData_setNull(data_ref)
                result = $(dpi_bind_function_name)(stmt.handle, position_or_name, type_information, data_ref) # native type is not examined since the value is passed as a NULL
                error_check(context(stmt), result)
                nothing
            end

        else
            # if the user passes a non-missing value, the type information is always inferred, avoiding type mismatches, as in `stmt[:flt] = 10.23`
            @assert type_information <: Nothing "Binding a non-missing value does not require type information argument."

            if value <: String
                ora_native_type_arg = :ORA_NATIVE_TYPE_BYTES
                set_data_function = :dpiData_setBytes

            elseif value <: Float64
                ora_native_type_arg = :ORA_NATIVE_TYPE_DOUBLE
                set_data_function = :dpiData_setDouble

            elseif value <: Int64
                ora_native_type_arg = :ORA_NATIVE_TYPE_INT64
                set_data_function = :dpiData_setInt64

            elseif value <: OraTimestamp
                ora_native_type_arg = :ORA_NATIVE_TYPE_TIMESTAMP
                set_data_function = :dpiData_setTimestamp

            else
                error("value type not supported: $value.")
            end

            return quote
                check_bind_bounds(stmt, position_or_name)
                data_ref = Ref{OraData}()
                $(set_data_function)(data_ref, value)
                result = $(dpi_bind_function_name)(stmt.handle, position_or_name, $ora_native_type_arg, data_ref)
                error_check(context(stmt), result)
                nothing
            end
        end
    end
end
