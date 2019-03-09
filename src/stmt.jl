
@inline column_name(query_info::OraQueryInfo) = unsafe_string(query_info.name, query_info.name_length)

function ncol(stmt::QueryStmt)
    if stmt.columns_info == nothing
        init_columns_info!(stmt)
    end
    return length(stmt.columns_info)
end

function columns_info(stmt::QueryStmt) :: Vector{OraQueryInfo}
    if stmt.columns_info == nothing
        init_columns_info!(stmt)
    end

    return stmt.columns_info
end

function column_info(stmt::QueryStmt, column_index::Integer) :: OraQueryInfo
    if stmt.columns_info == nothing
        init_columns_info!(stmt)
    end

    return stmt.columns_info[column_index]
end

@inline function oracle_type(stmt::QueryStmt, column_index::Integer) :: OraOracleTypeNum
    return column_info(stmt, column_index).type_info.oracle_type_num
end

function init_columns_info!(stmt::QueryStmt)

    function get_stmt_num_columns(ctx::Context, stmt_handle::Ptr{Cvoid})
        num_columns_ref = Ref{UInt32}(0)
        result = dpiStmt_getNumQueryColumns(stmt_handle, num_columns_ref)
        error_check(ctx, result)
        return num_columns_ref[]
    end

    function get_query_column_info(ctx::Context, stmt_handle::Ptr{Cvoid}, column_index::Integer)
        query_info_ref = Ref{OraQueryInfo}()
        result = dpiStmt_getQueryInfo(stmt_handle, UInt32(column_index), query_info_ref)
        error_check(context(stmt), result)
        return query_info_ref[]
    end

    columns_info = Vector{OraQueryInfo}()
    for col in 1:get_stmt_num_columns(context(stmt), stmt.handle)
        push!(columns_info, get_query_column_info(context(stmt), stmt.handle, col))
    end

    stmt.columns_info = columns_info
    nothing
end

function Stmt(connection::Connection, handle::Ptr{Cvoid}, scrollable::Bool; fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)

    function new_stmt_info(ctx::Context, stmt_handle::Ptr{Cvoid})
        stmt_info_ref = Ref{OraStmtInfo}()
        result = dpiStmt_getInfo(stmt_handle, stmt_info_ref)
        error_check(ctx, result)
        return StmtInfo(stmt_info_ref[])
    end

    function get_bind_count(ctx::Context, stmt_handle::Ptr{Cvoid})
        count_ref = Ref{UInt32}()
        result = dpiStmt_getBindCount(stmt_handle, count_ref)
        error_check(ctx, result)
        return count_ref[]
    end

    function get_bind_names(ctx::Context, stmt_handle::Ptr{Cvoid}, expected_num_bind_names::UInt32)
        num_bind_names_ref = Ref{UInt32}(expected_num_bind_names) # IN/OUT parameter
        bind_names_vec = undef_vector(Ptr{UInt8}, expected_num_bind_names)

        bind_name_lenghts_vec = zeros(UInt32, expected_num_bind_names)
        result = dpiStmt_getBindNames(stmt_handle, num_bind_names_ref, pointer(bind_names_vec), pointer(bind_name_lenghts_vec))
        error_check(ctx, result)

        @assert expected_num_bind_names == num_bind_names_ref[]

        result_names = undef_vector(String, expected_num_bind_names)

        for i in 1:expected_num_bind_names
            @inbounds result_names[i] = unsafe_string(bind_names_vec[i], bind_name_lenghts_vec[i])
        end

        return result_names
    end

    stmt_info = new_stmt_info(context(connection), handle)

    bind_count = get_bind_count(context(connection), handle)

    if bind_count == 0
        bind_names = Vector{String}()
        bind_names_index = Dict{String, UInt32}()
    else
        bind_names = get_bind_names(context(connection), handle, bind_count)
        bind_names_index = Dict{String, UInt32}()

        for (i, s) in enumerate(bind_names)
            bind_names_index[s] = i
        end
    end

    new_stmt = Stmt{stmt_info.statement_type}(connection, handle, scrollable, stmt_info, bind_count, bind_names, bind_names_index, true, nothing)
    fetch_array_size!(new_stmt, fetch_array_size)
    @compat finalizer(destroy!, new_stmt)
    return new_stmt
end

function Stmt(connection::Connection, sql::String; scrollable::Bool=false, tag::String="", fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    stmt_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_prepareStmt(connection.handle, scrollable, sql, tag, stmt_handle_ref)
    error_check(connection.context, result)
    return Stmt(connection, stmt_handle_ref[], scrollable, fetch_array_size=fetch_array_size)
end

function stmt(f::Function, connection::Connection, sql::String; scrollable::Bool=false, tag::String="", fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    stmt = Stmt(connection, sql, scrollable=scrollable, tag=tag, fetch_array_size=fetch_array_size)

    try
        f(stmt)
    finally
        close(stmt)
    end

    nothing
end

"Number of affected rows in a DML statement."
function row_count(stmt::Stmt)
    row_count_ref = Ref{UInt64}()
    result = dpiStmt_getRowCount(stmt.handle, row_count_ref)
    error_check(context(stmt), result)
    return row_count_ref[]
end

"""
    execute(stmt::Stmt; exec_mode::dpiExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32

Returns the number of columns which are being queried.
If the statement does not refer to a query, the value is set to 0.
"""
function execute(stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    num_columns_ref = Ref{UInt32}(0)
    result = dpiStmt_execute(stmt.handle, exec_mode, num_columns_ref)
    error_check(context(stmt), result)
    return num_columns_ref[]
end

function execute(connection::Connection, sql::String; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    local result::UInt32

    stmt(connection, sql, scrollable=scrollable, tag=tag) do stmt
        result = execute(stmt, exec_mode=exec_mode)
    end

    return result
end

function execute_script(connection::Connection, filepath::String; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    @assert isfile(filepath) "Couldn't find script file $filepath."

    local sql::String
    open(filepath, "r") do io
        sql = read(io, String)
    end

    return execute(connection, sql, scrollable=scrollable, tag=tag, exec_mode=exec_mode)
end

# execute many
function execute(connection::Connection, sql::String, columns::Vector; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    local result::UInt32

    stmt(connection, sql, scrollable=scrollable, tag=tag) do stmt
        result = execute(stmt, columns, exec_mode=exec_mode)
    end

    return result
end

# execute many
function execute(stmt::Stmt, columns::Vector; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32
    @assert !isempty(columns) "Cannot bind empty columns to statement."
    @assert eltype(columns) <: Vector "`columns` argument is expected to be a vector of vectors."

    function check_columns_length(columns::Vector)
        columns_count = length(columns)

        if columns_count <= 1
            return
        end

        first_column_length = length(columns[1])

        for i in 2:length(columns)
            @inbounds @assert length(columns[i]) == first_column_length
        end

        nothing
    end

    check_columns_length(columns)

    for (c, column) in enumerate(columns)
        stmt[c] = Variable(stmt.connection, column)
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
            @inbounds row_counts[i] = unsafe_load(row_counts_array_as_ptr, i)
        end

        return row_counts
    end

    return sum(row_counts(stmt))
end


function close(stmt::Stmt; tag::String="")
    if stmt.is_open
        result = dpiStmt_close(stmt.handle, tag=tag)
        error_check(context(stmt), result)
        stmt.is_open = false
    end
    nothing
end

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
    fetch(stmt::Stmt) :: FetchResult

Fetches a single row from the statement.
"""
function fetch(stmt::Stmt) :: FetchResult
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

function fetchrows(stmt::Stmt, max_rows::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE) :: FetchRowsResult
    buffer_row_index_ref = Ref{UInt32}()
    num_rows_fetched_ref = Ref{UInt32}()
    more_rows_ref = Ref{Int32}()

    result = dpiStmt_fetchRows(stmt.handle, UInt32(max_rows), buffer_row_index_ref, num_rows_fetched_ref, more_rows_ref)
    error_check(context(stmt), result)
    return FetchRowsResult(buffer_row_index_ref[], num_rows_fetched_ref[], more_rows_ref[])
end

function query_oracle_value(stmt::Stmt, column_index::Integer) :: ExternOracleValue
    native_type_ref = Ref{OraNativeTypeNum}()
    data_handle_ref = Ref{Ptr{OraData}}()
    result = dpiStmt_getQueryValue(stmt.handle, UInt32(column_index), native_type_ref, data_handle_ref)
    error_check(context(stmt), result)

    return ExternOracleValue(stmt, oracle_type(stmt, column_index), native_type_ref[], data_handle_ref[]; use_add_ref=true)
end
