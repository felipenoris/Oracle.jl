
#=
for i in iter   # or  "for i = iter"
    # body
end

is translated into:

next = iterate(iter)
while next !== nothing
    (i, state) = next
    # body
    next = iterate(iter, state)
end
=#

function CursorSchema(stmt::Stmt)
    @assert is_query(stmt) "Cannot create a Cursor for a statement that is not a Query."

    num_columns = num_query_columns(stmt)

    column_query_info = Vector{dpiQueryInfo}()
    column_names = Vector{String}()

    for column_index in 1:num_columns
        q_info = dpiQueryInfo(stmt, column_index)
        push!(column_query_info, q_info)
        push!(column_names, column_name(q_info))
    end

    return CursorSchema(stmt, column_query_info, column_names)
end

num_query_columns(schema::CursorSchema) = length(schema.column_names)
num_query_columns(cursor::Cursor) = num_query_columns(cursor.schema)
num_query_columns(row::ResultSetRow) = num_query_columns(row.cursor)

function Cursor(stmt::Stmt; fetch_array_size::Integer=DPI_DEFAULT_FETCH_ARRAY_SIZE)
    @assert stmt.executed "Cannot create Cursor for a non-executed statement."
    schema = CursorSchema(stmt)
    return Cursor(stmt, schema, fetch_array_size)
end

@inline function has_more_rows(r::FetchRowsResult)
    if r.more_rows == 1
        return true
    elseif r.more_rows == 0
        return false
    else
        error("Unexpected value for FetchRowsResult.more_rows: $(r.more_rows)")
    end
end

#=
Cursor is an iterator where state::CursorIteratorState
=#
function Base.iterate(cursor::Cursor)
    # this is the first iteration
    fetch_rows_result = Oracle.fetch_rows!(cursor.stmt, cursor.fetch_array_size)

    # check for empty result
    if fetch_rows_result.num_rows_fetched == 0
        return nothing
    end

    # If we fetch 3 rows, offsets are: -2, -1, 0. So we start at offset -2.
    offset = first_offset(fetch_rows_result)
    return (ResultSetRow(cursor, offset), CursorIteratorState(offset + 1, fetch_rows_result))
end

function Base.iterate(cursor::Cursor, state::CursorIteratorState)
    if state.next_offset <= 0
        # next row was already fetched
        return (ResultSetRow(cursor, state.next_offset), CursorIteratorState(state.next_offset + 1, state.last_fetch_rows_result))
    else
        # fetch more results if has more rows to fetch
        if has_more_rows(state.last_fetch_rows_result)
            fetch_rows_result = Oracle.fetch_rows!(cursor.stmt, cursor.fetch_array_size)

            # there should be more rows to fetch
            @assert fetch_rows_result.num_rows_fetched != 0

            offset = first_offset(fetch_rows_result)
            return (ResultSetRow(cursor, offset), CursorIteratorState(offset + 1, fetch_rows_result))
        else
            # there are no more rows to fetch, so we exausted this cursor
            close!(cursor.stmt)
            return nothing
        end
    end
end

first_offset(result::FetchRowsResult) = -Int(result.num_rows_fetched) + 1

function query(conn::Connection, sql::String; scrollable::Bool=false, tag::String="", exec_mode::dpiExecMode=DPI_MODE_EXEC_DEFAULT, fetch_array_size::Integer=DPI_DEFAULT_FETCH_ARRAY_SIZE)
    stmt = Stmt(conn, sql; scrollable=scrollable, tag=tag)
    return query(stmt; exec_mode=exec_mode, fetch_array_size=fetch_array_size)
end

function query(stmt::Stmt; exec_mode::dpiExecMode=DPI_MODE_EXEC_DEFAULT, fetch_array_size::Integer=DPI_DEFAULT_FETCH_ARRAY_SIZE)
    execute!(stmt; exec_mode=exec_mode)
    return Cursor(stmt; fetch_array_size=fetch_array_size)
end
