
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
