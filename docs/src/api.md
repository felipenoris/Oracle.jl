
# API Reference

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

## Driver Info

```@docs
Oracle.odpi_version
```

## Connection

```@docs
Oracle.Connection
Oracle.ping
Oracle.commit
Oracle.rollback
Oracle.set_client_identifier
Oracle.set_client_info
```

## Statement

```@docs
Oracle.execute
Oracle.row_count
Oracle.fetch_array_size!
Oracle.fetch
```

## Variable

```@docs
Oracle.get_returned_data
Oracle.define
```

## Lob

```@docs
Oracle.chunk_size
```

## Misc

```@docs
Oracle.odpi_version
```
