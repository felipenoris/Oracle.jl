
# Tables interface
Tables.istable(::Type{ResultSet}) = true
Tables.rowaccess(::Type{ResultSet}) = true
Tables.rows(rs::ResultSet) = rs.rows
Tables.columnnames(rs::ResultSet) = [ Symbol(colname) for colname in names(rs) ]
Tables.columnnames(row::ResultSetRow) = [ Symbol(colname) for colname in names(row) ]
Tables.getcolumn(row::ResultSetRow, index::Symbol) = row[string(index)]
Tables.getcolumn(row::ResultSetRow, index::Integer) = row[index]
