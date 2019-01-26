
function CursorSchema(stmt::QueryStmt)

    columns_count = num_columns(stmt)

    column_query_info = Vector{OraQueryInfo}()
    column_names_index = Dict{String, Int}()

    for column_index in 1:columns_count
        q_info = OraQueryInfo(stmt, column_index)
        push!(column_query_info, q_info)
        column_names_index[column_name(q_info)] = column_index
    end

    return CursorSchema(column_query_info, column_names_index)
end

num_columns(schema::CursorSchema) = length(schema.column_names_index)
num_columns(row::ResultSetRow) = num_columns(row.cursor)
num_columns(cursor::Cursor) = num_columns(cursor.stmt)

stmt(cursor::Cursor) = cursor.stmt

function Cursor(stmt::QueryStmt)
    schema = CursorSchema(stmt)
    return Cursor(stmt, schema)
end

@static if VERSION < v"0.7-"
    # Iteration protocol for Julia v0.6

    #=
    for i = I   # or  "for i in I"
        # body
    end
    is translated into:

    state = start(I)
    while !done(I, state)
        (i, state) = next(I, state)
        # body
    end
    =#

    function Base.start(cursor::Cursor) :: FetchResult
        return fetch!(cursor.stmt)
    end

    function Base.done(cursor::Cursor, state::FetchResult)
        return !state.found
    end

    function Base.next(cursor::Cursor, state::FetchResult)
        current_row = ResultSetRow(cursor)
        next_state = fetch!(cursor.stmt)
        return (current_row, next_state)
    end

else
    # Iteration protocol for Julia v0.7 and v1.0

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

    function Base.iterate(cursor::Cursor, nil::Nothing=nothing)
        fetch_result = fetch!(cursor.stmt)
        if fetch_result.found
            current_row = ResultSetRow(cursor)
            return (current_row, nothing)
        else
            return nothing
        end
    end
end

function query(f::Function, conn::Connection, sql::String; scrollable::Bool=false, tag::String="", exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT, fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE)
    stmt(conn, sql, scrollable=scrollable, tag=tag) do stmt
        fetch_array_size!(stmt, fetch_array_size)
        execute!(stmt, exec_mode=exec_mode)
        cursor = Cursor(stmt)
        f(cursor)
    end
    nothing
end

function query(f::Function, stmt::Stmt, exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT)
    execute!(stmt, exec_mode=exec_mode)
    f(Cursor(stmt))
    nothing
end

function ResultSetRow(cursor::Cursor)
    data = Vector{Any}()

    # parse data from Cursor
    for column_index in 1:num_columns(cursor)
        val = query_value(stmt(cursor), column_index)
        push!(data, parse_value(cursor.schema.column_query_info[column_index], val))
    end

    return ResultSetRow(cursor, data)
end

Base.getindex(row::ResultSetRow, column_index::Integer) = row.data[column_index]

function Base.getindex(row::ResultSetRow, column_name::AbstractString)
    column_index = row.cursor.schema.column_names_index[column_name]
    return row.data[column_index]
end

has_possibly_more_rows(r::FetchRowsResult) = Bool(r.more_rows)

Base.IteratorSize(::Cursor) = Base.SizeUnknown()
Base.eltype(::Cursor) = ResultSetRow

@static if VERSION < v"0.7-"
    function Base.collect(cursor::Cursor)
        result = Vector{eltype(cursor)}()
        for row in cursor
            push!(result, row)
        end
        return result
    end
end
