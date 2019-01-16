
# Oracle.jl

This package provides a driver to access Oracle databases using the Julia language,
based on [odpi](https://github.com/oracle/odpi) bindings.

## Development Notice

This package is under development.

It's planned to be a functional package by the end of January 2019.

## Instant Client installation

* [Download](https://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html) instant client.

* Unzip and add `instantclient` folder to your LD_LIBRARY_PATH:

```
export LD_LIBRARY_PATH=/path-to-folder/instantclient_XX_Y:$LD_LIBRARY_PATH
```

## ODPI-C Naming Conventions

All enums, constants and structs in ODPI-C library use the prefix `DPI` or `dpi`.

In *Oracle.jl*, the Julia implementation of these elements use the prefix `ORA` or `Ora`.

Examples:

* The ODPI-C constant `DPI_MODE_AUTH_SYSDBA` becomes `ORA_MODE_AUTH_SYSDBA` in Julia.

* The ODPI-C enum `dpiAuthMode` becomes `OraAuthMode` in Julia.

* The ODPI-C struct `dpiTimestamp` becomes `OraTimestamp` in Julia.

All julia structs with prefix `Ora` are raw wrappers around ODPC-C structs and may contain unsafe attributes.

Safe equivalent Julia structs drop the `Ora` prefix.

ODPI-C *function wrappers* have their name preserved, as in `dpiContext_create`.

## Tutorial

### Getting a Connection

```julia
import Oracle

username = "my_username"
password = "my_password"
connect_string = "//IP_ADDRESS/XE" # a valid Oracle connect string

conn = Oracle.Connection(username, password, connect_string)
```

The default encoding for CHAR and NCHAR is UTF-8.

To connect as SYSDBA, use the appropriate `auth_mode` parameter.

```julia
conn = Oracle.Connection(username, password, connect_string, auth_mode=Oracle.ORA_MODE_AUTH_SYSDBA)
```

Connections are closed automatically when they go out of scope. But you can also close a connection using `Oracle.close!` method.

```julia
Oracle.close!(conn)
```

### Executing a Statement

```julia
Oracle.execute!(conn, "CREATE TABLE TB_TEST ( ID INT NULL )")
Oracle.execute!(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 1 )")
Oracle.execute!(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( null )")
Oracle.commit!(conn) # will commit 2 lines

Oracle.execute!(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 3 )")
Oracle.rollback!(conn) # abort insertion of the third line
```

### Binding values to a Statement

```julia
Oracle.execute!(conn, "CREATE TABLE TB_BIND ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)")

stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )")

# will add 10 lines to TB_BIND
for i in 1:10
    stmt[:id] = 1 + i
    stmt[:flt] = 10.23 + i
    stmt[:str] = "🍕 $i"
    stmt[:dt] = Date(2018,12,31) + Dates.Day(i)
    Oracle.execute!(stmt)
end
Oracle.commit!(conn)
```

### Executing a Query

```julia
for row in Oracle.query(conn, "SELECT * FROM TB_BIND")
    println( row["ID"]  )
    println( row["FLT"] )
    println( row["STR"] )
    println( row["DT"]  )
end
```
