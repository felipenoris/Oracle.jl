
function CursorSchema(stmt::Stmt, num_query_columns::Integer=num_query_columns(stmt))
    @assert is_query(stmt) "Cannot create a Cursor for a statement that is not a Query."

    column_query_info = Vector{dpiQueryInfo}()
    column_names = Vector{String}()

    for column_index in 1:num_query_columns
        q_info = dpiQueryInfo(stmt, column_index)
        push!(column_query_info, q_info)
        push!(column_names, column_name(q_info))
    end

    return CursorSchema(stmt, column_query_info, column_names)
end

num_query_columns(schema::CursorSchema) = length(schema.column_names)
num_query_columns(cursor::Cursor) = num_query_columns(cursor.schema)

function Cursor(stmt::Stmt, num_query_columns::Integer=num_query_columns(stmt))
    schema = CursorSchema(stmt, num_query_columns)
    return Cursor(stmt, schema)
end
