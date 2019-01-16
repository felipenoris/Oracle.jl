
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

function CursorSchema(execution_result::QueryExecutionResult)
    stmt = execution_result.stmt
    num_columns = execution_result.num_columns

    column_query_info = Vector{OraQueryInfo}()
    column_names_index = Dict{String, Int}()

    for column_index in 1:num_columns
        q_info = OraQueryInfo(stmt, column_index)
        push!(column_query_info, q_info)
        column_names_index[column_name(q_info)] = column_index
    end

    return CursorSchema(stmt, column_query_info, column_names_index)
end

num_columns(schema::CursorSchema) = length(schema.column_names_index)
num_columns(row::ResultSetRow) = num_columns(row.cursor)
num_columns(cursor::Cursor) = cursor.execution_result.num_columns

stmt(cursor::Cursor) = cursor.execution_result.stmt

function Cursor(execution_result::QueryExecutionResult; fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    schema = CursorSchema(execution_result)
    return Cursor(execution_result, schema, fetch_array_size)
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

@static if VERSION < v"0.7-"
    # Iteration protocol for Julia v0.6

    function Base.start(cursor::Cursor)
        fetch_rows_result = Oracle.fetch_rows!(stmt(cursor), cursor.fetch_array_size)
        return CursorIteratorState(first_offset(fetch_rows_result), fetch_rows_result)
    end

    function Base.done(cursor::Cursor, state::CursorIteratorState)
        if state.next_offset <= 0
            # next row was already fetched
            return false
        end

        if !has_more_rows(state.last_fetch_rows_result)
            # there are no more rows to fetch
            close!(stmt(cursor))
            return true
        end

        # sometimes after we fetch rows we discover that the result is empty
        fetch_rows_result = Oracle.fetch_rows!(stmt(cursor), cursor.fetch_array_size)

        if fetch_rows_result.num_rows_fetched == 0
            # fetch returned no more rows
            return true
        else
            # mutate current state
            state.next_offset = first_offset(fetch_rows_result)
            state.last_fetch_rows_result = fetch_rows_result
            return false
        end
    end

    function Base.next(cursor::Cursor, state::CursorIteratorState)
        # next row was already fetched
        @assert state.next_offset <= 0 "Cursor in inconsistent state."
        return (ResultSetRow(cursor, state.next_offset), CursorIteratorState(state.next_offset + 1, state.last_fetch_rows_result))
    end

else
    # Iteration protocol for Julia v0.7 and v1.0

    #=
    Cursor is an iterator where state::CursorIteratorState
    =#
    function Base.iterate(cursor::Cursor)
        # this is the first iteration
        fetch_rows_result = Oracle.fetch_rows!(stmt(cursor), cursor.fetch_array_size)

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
                fetch_rows_result = Oracle.fetch_rows!(stmt(cursor), cursor.fetch_array_size)

                # it's strange, but sometimes `has_more_rows` returns true, and `fetch_rows!` returns `num_rows_fetched == 0`
                if fetch_rows_result.num_rows_fetched == 0
                    close!(stmt(cursor))
                    return nothing
                end

                offset = first_offset(fetch_rows_result)
                return (ResultSetRow(cursor, offset), CursorIteratorState(offset + 1, fetch_rows_result))
            else
                # there are no more rows to fetch, so we finished reading from this Cursor
                close!(stmt(cursor))
                return nothing
            end
        end
    end
end

first_offset(result::FetchRowsResult) = -Int(result.num_rows_fetched) + 1

function query(conn::Connection, sql::String; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT, fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    stmt = Stmt(conn, sql; scrollable=scrollable, tag=tag)
    return query(stmt; exec_mode=exec_mode, fetch_array_size=fetch_array_size)
end

function query(stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT, fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    return query( execute!(stmt; exec_mode=exec_mode) ; fetch_array_size=fetch_array_size)
end

function query(result::QueryExecutionResult; fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    return Cursor(result; fetch_array_size=fetch_array_size)
end

function ResultSetRow(cursor::Cursor, offset::Int)
    data = Vector{Any}()

    # parse data from Cursor
    for column_index in 1:num_columns(cursor)
        native_value = query_value(stmt(cursor), column_index)[offset]
        push!(data, parse_value(cursor.schema.column_query_info[column_index], native_value))
    end

    return ResultSetRow(cursor, offset, data)
end

Base.getindex(row::ResultSetRow, column_index::Integer) = row.data[column_index]

function Base.getindex(row::ResultSetRow, column_name::AbstractString)
    column_index = row.cursor.schema.column_names_index[column_name]
    return row.data[column_index]
end
