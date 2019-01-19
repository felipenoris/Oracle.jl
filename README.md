
# Oracle.jl

This package provides a driver to access Oracle databases using the Julia language,
based on [ODPI-C](https://github.com/oracle/odpi) bindings.

## Requirements

* [Julia](https://julialang.org/) v0.6, v0.7 or v1.0.

* Oracle's [Instant Client](https://www.oracle.com/technetwork/database/database-technologies/instant-client/overview/index.html).

* Linux or macOS.

* C compiler.

## Instant Client installation

This package requires Oracle's [Instant Client](https://www.oracle.com/technetwork/database/database-technologies/instant-client/overview/index.html).

To install it, follow these instructions:

* [Download](https://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html) instant client.

* Unzip and add `instantclient` folder to your LD_LIBRARY_PATH:

```
export LD_LIBRARY_PATH=/path-to-folder/instantclient_XX_Y:$LD_LIBRARY_PATH
```

Alternative installation methods are available at [ODPI-C documentation](https://oracle.github.io/odpi/doc/installation.html), or at [Instant Client documentation](https://www.oracle.com/technetwork/database/database-technologies/instant-client/documentation/index.html).

## Package installation

Using Julia v1.0 package REPL:

```julia
(v1.0) pkg> add https://github.com/felipenoris/Oracle.jl.git
```

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

Connections are closed automatically (by the garbage collector) when they go out of scope. But you can also close a connection using `Oracle.close!` method.

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
Oracle.close!(stmt)
```

Statements are closed automatically (by the garbage collector) when they go out of scope.
But it's good practice to close it using `Oracle.close!` method as soon as you have
finished with it, to release database resources.

### Executing a Query

Use `Oracle.query` method with *do-syntax* to get a reference to a cursor.

```julia
Oracle.query(conn, "SELECT * FROM TB_BIND") do cursor
    for row in cursor
        println( row["ID"]  )
        println( row["FLT"] )
        println( row["STR"] )
        println( row["DT"]  )
    end
end
```

You can also use a prepared statement to execute a query.

```julia
stmt = Oracle.Stmt(conn, "SELECT FLT FROM TB_BIND WHERE ID = :id")
stmt[:id] = 1

Oracle.query(stmt) do cursor
    for row in cursor
      println(row["FLT"])
    end
end

Oracle.close!(stmt)
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

## License

The source code for the package *Oracle.jl* is licensed under the [MIT License](https://github.com/felipenoris/Oracle.jl/blob/master/LICENSE).

During installation, *Oracle.jl* downloads the source code and compile the library [ODPI-C](https://github.com/oracle/odpi)
which is licensed under [The Universal Permissive License (UPL), Version 1.0](https://oracle.github.io/odpi/doc/license.html) and/or the [Apache License](https://oracle.github.io/odpi/doc/license.html).
