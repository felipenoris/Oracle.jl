
function stmt(f::Function, connection::Connection, sql::String; scrollable::Bool=false, tag::String="")
    stmt = Stmt(connection, sql, scrollable=scrollable, tag=tag)

    try
        f(stmt)
    finally
        close!(stmt)
    end

    nothing
end

function Stmt(connection::Connection, sql::String; scrollable::Bool=false, tag::String="")
    stmt_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_prepareStmt(connection.handle, scrollable, sql, tag, stmt_handle_ref)
    error_check(connection.context, result)
    return Stmt(connection, stmt_handle_ref[], scrollable)
end

"Number of affected rows in a DML statement."
function row_count(stmt::Stmt)
    row_count_ref = Ref{UInt64}()
    result = dpiStmt_getRowCount(stmt.handle, row_count_ref)
    error_check(context(stmt), result)
    return row_count_ref[]
end

"""
    execute!(stmt::Stmt; exec_mode::dpiExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32

Returns the number of columns which are being queried.
If the statement does not refer to a query, the value is set to 0.
"""
function execute!(stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    num_columns_ref = Ref{UInt32}(0)
    result = dpiStmt_execute(stmt.handle, exec_mode, num_columns_ref)
    error_check(context(stmt), result)
    return num_columns_ref[]
end

function execute!(connection::Connection, sql::String; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    local result::UInt32

    stmt(connection, sql, scrollable=scrollable, tag=tag) do stmt
        result = execute!(stmt, exec_mode=exec_mode)
    end

    return result
end

# execute many
function execute!(connection::Connection, sql::String, columns::Vector; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    local result::UInt32

    stmt(connection, sql, scrollable=scrollable, tag=tag) do stmt
        result = execute!(stmt, columns, exec_mode=exec_mode)
    end

    return result
end

# execute many
function execute!(stmt::Stmt, columns::Vector; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    @assert !isempty(columns) "Cannot bind empty columns to statement."
    @assert eltype(columns) <: Vector

    function check_columns_length(columns::Vector)
        columns_count = length(columns)

        if columns_count <= 1
            return
        end

        first_column_length = length(columns[1])

        for i in 2:length(columns)
            @assert length(columns[i]) == first_column_length
        end

        nothing
    end

    check_columns_length(columns)

    for (c, column) in enumerate(columns)
        stmt[c] = build_variable(stmt.connection, column)
    end

    # execute
    rows_count = length(columns[1])
    result = dpiStmt_executeMany(stmt.handle, exec_mode | ORA_MODE_EXEC_ARRAY_DML_ROWCOUNTS, UInt32(rows_count))
    error_check(context(stmt), result)

    # get row counts
    function row_counts(stmt::Stmt) :: Vector{UInt64}
        row_counts_length_ref = Ref{UInt32}()
        row_counts_array_ref = Ref{Ptr{UInt64}}()
        result = dpiStmt_getRowCounts(stmt.handle, row_counts_length_ref, row_counts_array_ref)
        error_check(context(stmt), result)

        row_counts_length = row_counts_length_ref[]
        row_counts_array_as_ptr = row_counts_array_ref[]

        row_counts = undef_vector(UInt64, row_counts_length)
        for i in 1:row_counts_length
            row_counts[i] = unsafe_load(row_counts_array_as_ptr, i)
        end

        return row_counts
    end

    return sum(row_counts(stmt))
end


function close!(stmt::Stmt; tag::String="")
    if stmt.is_open
        result = dpiStmt_close(stmt.handle, tag=tag)
        error_check(context(stmt), result)
        stmt.is_open = false
    end
    nothing
end

"""
    num_columns(stmt::QueryStmt) :: UInt32

Returns the number of columns that are being queried.
`stmt` must be an executed statement.
"""
function num_columns(stmt::QueryStmt) :: UInt32
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

function fetch_array_size(stmt::Stmt) :: UInt32
    array_size_ref = Ref{UInt32}()
    result = dpiStmt_getFetchArraySize(stmt.handle, array_size_ref)
    error_check(context(stmt), result)
    return array_size_ref[]
end

"""
    fetch_array_size!(stmt::Stmt, new_size::Integer)

Sets the array size used for performing fetches.
All variables defined for fetching must have this many (or more) elements allocated for them.
The higher this value is the less network round trips are required to fetch rows from the database
but more memory is also required.

A value of zero will reset the array size to the default value of DPI_DEFAULT_FETCH_ARRAY_SIZE.
"""
function fetch_array_size!(stmt::Stmt, new_size::Integer)
    result = dpiStmt_setFetchArraySize(stmt.handle, UInt32(new_size))
    error_check(context(stmt), result)
    nothing
end

reset_fetch_array_size!(stmt::Stmt) = fetch_array_size!(stmt, UInt32(0))

"""
    fetch!(stmt::Stmt) :: FetchResult

Fetches a single row from the statement.
"""
function fetch!(stmt::Stmt) :: FetchResult
    found_ref = Ref{Int32}(0)
    buffer_row_index_ref = Ref{UInt32}(0) # This index is used as the array position for getting values from the variables that have been defined for the statement.
    result = dpiStmt_fetch(stmt.handle, found_ref, buffer_row_index_ref)
    error_check(context(stmt), result)

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

function query_value(stmt::Stmt, column_index::Integer)
    native_type_ref = Ref{OraNativeTypeNum}()
    data_handle_ref = Ref{Ptr{OraData}}()
    result = dpiStmt_getQueryValue(stmt.handle, UInt32(column_index), native_type_ref, data_handle_ref)
    error_check(context(stmt), result)

    # dpiStmt_getQueryValue() is intended to be paired with dpiStmt_fetch()
    # so NativeValue will return always a single value ( index = 0, or native_value[] ).
    # see https://github.com/oracle/odpi/issues/79
    return NativeValue(native_type_ref[], data_handle_ref[])[]
end

function check_bind_bounds(stmt::Stmt, pos::Integer)
    @assert pos > 0 && pos <= stmt.bind_count "Bind position $pos out of bounds."
    nothing
end

function check_bind_bounds(stmt::Stmt, name::String)
    name_upper = uppercase(name)
    @assert haskey(stmt.bind_names_index, name_upper) "Bind name $name_upper not found in statement."
end

check_bind_bounds(stmt::Stmt, name::Symbol) = check_bind_bounds(stmt, string(name))

#
# Bind Value to Stmt
#

const NameOrPositionTypes = Union{Integer, String, Symbol}
const NonMissingBindValueTypes = Union{String, OraTimestamp, Int, Float64}
const BindValueJuliaTypes = Union{Missing, NonMissingBindValueTypes, Dates.TimeType}

function Base.setindex!(stmt::Stmt, value::B, name_or_position::K) where {B<:Union{NonMissingBindValueTypes, Dates.TimeType}, K<:NameOrPositionTypes}
    return bind_value!(stmt, value, name_or_position)
end

function Base.setindex!(stmt::Stmt, m::Missing, name_or_position::K, type_information::T) where {K<:NameOrPositionTypes, T}
    return bind_value!(stmt, m, name_or_position, type_information)
end

function bind_value!(stmt::Stmt, value::NonMissingBindValueTypes, name::Union{String, Symbol}, native_type::OraNativeTypeNum, set_data_function::F) where {F<:Function}
    check_bind_bounds(stmt, name)
    data_ref = Ref{OraData}()
    set_data_function(data_ref, value)
    result = dpiStmt_bindValueByName(stmt.handle, string(name), native_type, data_ref)
    error_check(context(stmt), result)
    nothing
end

function bind_value!(stmt::Stmt, value::NonMissingBindValueTypes, pos::Integer, native_type::OraNativeTypeNum, set_data_function::F) where {F<:Function}
    check_bind_bounds(stmt, pos)
    data_ref = Ref{OraData}()
    set_data_function(data_ref, value)
    result = dpiStmt_bindValueByPos(stmt.handle, UInt32(pos), native_type, data_ref)
    error_check(context(stmt), result)
    nothing
end

function bind_value!(stmt::Stmt, ::Missing, name::Union{String, Symbol}, native_type::OraNativeTypeNum)
    check_bind_bounds(stmt, name)
    data_ref = Ref{OraData}()
    dpiData_setNull_ref(data_ref)
    result = dpiStmt_bindValueByName(stmt.handle, string(name), native_type, data_ref) # native type is not examined since the value is passed as a NULL
    error_check(context(stmt), result)
    nothing
end

function bind_value!(stmt::Stmt, ::Missing, pos::Integer, native_type::OraNativeTypeNum)
    check_bind_bounds(stmt, pos)
    data_ref = Ref{OraData}()
    dpiData_setNull_ref(data_ref)
    result = dpiStmt_bindValueByPos(stmt.handle, UInt32(pos), native_type, data_ref) # native type is not examined since the value is passed as a NULL
    error_check(context(stmt), result)
    nothing
end

function bind_value!(stmt::Stmt, m::Missing, name_or_position::N, julia_type::Type{T}) where {T<:Union{NonMissingBindValueTypes, Dates.TimeType}, N<:NameOrPositionTypes}
    return bind_value!(stmt, m, name_or_position, OraNativeTypeNum(julia_type))
end

function bind_value!(stmt::Stmt, value::T, name_or_position::N) where {T<:Dates.TimeType, N<:NameOrPositionTypes}
    bind_value!(stmt, OraTimestamp(value), name_or_position, ORA_NATIVE_TYPE_TIMESTAMP, dpiData_setTimestamp_ref)
end

bind_value!(stmt::Stmt, value::String, name::NameOrPositionTypes) = bind_value!(stmt, value, name, ORA_NATIVE_TYPE_BYTES, dpiData_setBytes_ref)
bind_value!(stmt::Stmt, value::Float64, name::NameOrPositionTypes) = bind_value!(stmt, value, name, ORA_NATIVE_TYPE_DOUBLE, dpiData_setDouble_ref)
bind_value!(stmt::Stmt, value::Int64, name::NameOrPositionTypes) = bind_value!(stmt, value, name, ORA_NATIVE_TYPE_INT64, dpiData_setInt64_ref)

#
# Bind OraVariable to Stmt
#

Base.setindex!(stmt::Stmt, value::OraVariable, name_or_position::NameOrPositionTypes) = bind_variable!(stmt, value, name_or_position)

@generated function bind_variable!(stmt::Stmt, variable::OraVariable, name_or_position::K) where {K<:NameOrPositionTypes}

    if name_or_position <: Integer
        name_or_position_exp = :(UInt32(name_or_position))
        bind_function_name = :dpiStmt_bindByPos
    elseif name_or_position <: Symbol
        name_or_position_exp = :(string(name_or_position))
        bind_function_name = :dpiStmt_bindByName
    elseif name_or_position <: String
        name_or_position_exp = :name_or_position
        bind_function_name = :dpiStmt_bindByName
    else
        error("Unsupported type for argument `name_or_position`: $name_or_position.")
    end

    return quote
        key = $name_or_position_exp
        check_bind_bounds(stmt, key)
        result = $(bind_function_name)(stmt.handle, key, variable.handle)
        error_check(context(stmt), result)
        nothing
    end
end
