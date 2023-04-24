
function CursorSchema(stmt::QueryStmt)

    columns_count = ncol(stmt)
    column_query_info = columns_info(stmt)

    column_names_index = Dict{String, Int}()

    for (column_index, query_info) in enumerate(column_query_info)
        column_names_index[column_name(query_info)] = column_index
    end

    return CursorSchema(column_query_info, column_names_index)
end

@inline ncol(schema::CursorSchema) = length(schema.column_names_index)
@inline ncol(row::ResultSetRow) = ncol(row.cursor)
@inline ncol(cursor::Cursor) = ncol(cursor.stmt)
@inline ncol(rs::ResultSet) = ncol(rs.schema)

@inline nrow(rs::ResultSet) = length(rs.rows)

Base.isempty(rs::ResultSet) = isempty(rs.rows)
Base.size(rs::ResultSet) = ( nrow(rs), ncol(rs) )

"""
    names(schema::CursorSchema) :: Vector{String}
    names(row::ResultSetRow) :: Vector{String}
    names(cursor::Cursor) :: Vector{String}
    names(rs::ResultSet) :: Vector{String}

Return a freshly allocated `Vector{String}` of names of columns contained in schema, row, cursor, or result set.
"""
Base.names(schema::CursorSchema) = [ column_name(orainfo) for orainfo in schema.column_query_info ]
Base.names(cursor::Cursor) = names(cursor.schema)
Base.names(row::ResultSetRow) = names(row.schema)
Base.names(rs::ResultSet) = names(rs.schema)

@inline stmt(cursor::Cursor) = cursor.stmt

function Cursor(stmt::QueryStmt)
    schema = CursorSchema(stmt)
    return Cursor(stmt, schema)
end

function Base.iterate(cursor::Cursor, nil::Nothing=nothing)
    fetch_result = fetch(cursor.stmt)
    if fetch_result.found
        current_row = ResultSetRow(cursor)
        return (current_row, nothing)
    else
        return nothing
    end
end

function query(f::Function, conn::Connection, sql::AbstractString;
               scrollable::Bool=false,
               tag::AbstractString="",
               fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE,
               exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT)

    stmt(conn, sql, scrollable=scrollable, tag=tag, fetch_array_size=fetch_array_size) do stmt
        execute(stmt, exec_mode=exec_mode)
        cursor = Cursor(stmt)
        f(cursor)
    end

    nothing
end

function execute_and_fetch_all!(stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: ResultSet
    local schema::CursorSchema
    rows = Vector{ResultSetRow}()

    query(stmt, exec_mode=exec_mode) do cursor
        schema = cursor.schema

        for row in cursor
            push!(rows, row)
        end
    end

    return ResultSet(schema, rows)
end

function query(f::Function, stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT)
    execute(stmt, exec_mode=exec_mode)
    f(Cursor(stmt))
    nothing
end

function query(stmt::Stmt; exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: ResultSet
    return execute_and_fetch_all!(stmt, exec_mode=exec_mode)
end

function query(conn::Connection, sql::AbstractString;
               scrollable::Bool=false,
               tag::AbstractString="",
               fetch_array_size::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE,
               exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT) :: ResultSet

    local rs::ResultSet

    stmt(conn, sql, scrollable=scrollable, tag=tag, fetch_array_size=fetch_array_size) do stmt
        rs = execute_and_fetch_all!(stmt, exec_mode=exec_mode)
    end

    return rs
end

function ResultSetRow(cursor::Cursor)
    data = Vector{Any}()

    # parse data from Cursor
    for column_index in 1:ncol(cursor)
        oracle_value = query_oracle_value(stmt(cursor), column_index)
        push!(data, parse_oracle_value(oracle_value))
    end

    return ResultSetRow(cursor.schema, data)
end

Base.length(row::ResultSetRow) = length(row.data)
Base.isempty(row::ResultSetRow) = isempty(row.data)

function Base.getindex(row::ResultSetRow, column_index::Integer)
    check_inbounds(row, column_index)
    @inbounds return row.data[column_index]
end

function Base.getindex(row::ResultSetRow, column_name::AbstractString)
    check_inbounds(row, column_name)
    column_index = row.schema.column_names_index[column_name]
    @inbounds return row.data[column_index]
end

@inline function check_inbounds(schema::CursorSchema, column::Integer)
    @assert 0 < column <= ncol(schema) "Column $column not found."
end

@inline function check_inbounds(schema::CursorSchema, column::AbstractString)
    @assert haskey(schema.column_names_index, column) "Column $column not found."
end

@inline check_inbounds(row::ResultSetRow, column::Union{AbstractString,Integer}) = check_inbounds(row.schema, column)

@inline function check_inbounds(rs::ResultSet, row::Integer, column::Union{AbstractString, Integer})
    check_inbounds(rs.schema, column)
    @assert 0 < row <= nrow(rs) "Row $row not found."
end

has_possibly_more_rows(r::FetchRowsResult) = Bool(r.more_rows)

Base.IteratorSize(::Cursor) = Base.SizeUnknown()
Base.eltype(::Cursor) = ResultSetRow

function fetchrow(stmt::QueryStmt) :: Union{Nothing, ResultSetRow}
    fetch_result = fetch(stmt)

    if fetch_result.found
        return ResultSetRow(Cursor(stmt))
    else
        return nothing
    end
end

function Base.getindex(rs::ResultSet, row::Integer, column::Union{AbstractString,Integer})
    check_inbounds(rs, row, column)
    return rs.rows[row][column]
end

function Base.getindex(rs::ResultSet, ::Colon, column::Union{AbstractString,Integer})
    column_data = Vector()

    !isempty(rs) && check_inbounds(rs.rows[1], column)

    for row in rs.rows
        push!(column_data, row[column])
    end

    return column_data
end

function Base.lastindex(rs::ResultSet, d::Integer)
    @assert d == 1 || d == 2 "Invalid dimension for ResultSet: $d."

    # rows
    if d == 1
        return nrow(rs)
    else
        # columns
        return ncol(rs)
    end
end

function Base.getindex(rs::ResultSet, row_range::UnitRange{T}, column::Union{AbstractString,Integer}) where {T<:Integer}
    column_data = Vector()

    for r in row_range
        check_inbounds(rs, r, column)
        push!(column_data, rs[r, column])
    end

    return column_data
end
