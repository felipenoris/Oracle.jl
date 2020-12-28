
# Tables interface
Tables.istable(::Type{ResultSet}) = true
Tables.rowaccess(::Type{ResultSet}) = true
Tables.rows(rs::ResultSet) = rs.rows
Tables.columnnames(rs::ResultSet) = [ Symbol(column_name(orainfo)) for orainfo in rs.schema.column_query_info ]
Tables.columnnames(row::ResultSetRow) = [ Symbol(column_name(orainfo)) for orainfo in row.schema.column_query_info ]
Tables.getcolumn(row::ResultSetRow, index::Symbol) = row[string(index)]
Tables.getcolumn(row::ResultSetRow, index::Integer) = row[index]
