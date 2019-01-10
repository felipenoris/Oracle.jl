
function ResultSetRow(cursor::Cursor, offset::Int)
    data = Vector{Any}()

    # parse data from Cursor
    for column_index in 1:num_query_columns(cursor)
        native_value = query_value(cursor.stmt, column_index)[offset]
        push!(data, parse_value(cursor.schema.column_query_info[column_index], native_value))
    end

    return ResultSetRow(cursor, offset, data)
end

function parse_value(column_info::dpiQueryInfo, m::Missing) :: Missing
    @assert ismissing(m) # sanity check
    @assert column_info.null_ok == 1 # if we got a null value, it must be ok for the schema to have a null value in this columns
    return missing
end

function parse_value(column_info::dpiQueryInfo, num::Float64)
    if column_info.type_info.oracle_type_num == DPI_ORACLE_TYPE_NUMBER && column_info.type_info.scale <= 0
        return Int(num)
    else
        return num
    end
end

function parse_value(column_info::dpiQueryInfo, val::T) :: T where {T}
    # catches all other cases
    val
end

Base.getindex(row::ResultSetRow, column_index::Integer) = row.data[column_index]

function Base.getindex(row::ResultSetRow, column_name::AbstractString)
    column_index = row.cursor.schema.column_names_index[column_name]
    return row.data[column_index]
end
