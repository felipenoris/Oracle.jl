var documenterSearchIndex = {"docs":
[{"location":"#Oracle.jl-1","page":"Home","title":"Oracle.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"This package provides a driver to access Oracle databases using the Julia language, based on ODPI-C bindings.","category":"page"},{"location":"#Development-Notice-1","page":"Home","title":"Development Notice","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"This package is under active development. Under version v0.1.0, there will be no deprecation warnings for API changes.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"You can check the release notes for a list of API changes between versions.","category":"page"},{"location":"#Requirements-1","page":"Home","title":"Requirements","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Julia v0.6, v0.7 or v1.0.\nOracle's Instant Client.\nLinux or macOS.\nC compiler.","category":"page"},{"location":"#Instant-Client-installation-1","page":"Home","title":"Instant Client installation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"This package requires Oracle's Instant Client.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"To install it, follow these instructions:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Download instant client.\nUnzip and add instantclient folder to your LDLIBRARYPATH:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"export LD_LIBRARY_PATH=/path-to-folder/instantclient_XX_Y:$LD_LIBRARY_PATH","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Check ODPI-C documentation, or Instant Client documentation for alternative installation methods.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"libaio is a dependency of Instant Client.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"If you have root access to your machine, you can install it using the package manager, as in:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"yum -y install libaio","category":"page"},{"location":"#","page":"Home","title":"Home","text":"If you don't have root access to your machine, you can compile it from source and set your LD_LIBRARY_PATH environment variable to point to the library.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The compilation can be done using the following script:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"wget https://pagure.io/libaio/archive/libaio-0.3.111/libaio-libaio-0.3.111.tar.gz\ntar xf libaio-libaio-0.3.111.tar.gz\ncd libaio-libaio-0.3.111\nmake prefix=$HOME/local\nmake install prefix=$HOME/local","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Then add the following to your shell profile ($HOME/.bashrc):","category":"page"},{"location":"#","page":"Home","title":"Home","text":"export LD_LIBRARY_PATH=$HOME/local/lib:$LD_LIBRARY_PATH","category":"page"},{"location":"#Package-installation-1","page":"Home","title":"Package installation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"julia> Pkg.add(\"Oracle\")","category":"page"},{"location":"#ODPI-C-Naming-Conventions-1","page":"Home","title":"ODPI-C Naming Conventions","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"All enums, constants and structs in ODPI-C library use the prefix DPI or dpi.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"In Oracle.jl, the Julia implementation of these elements use the prefix ORA or Ora.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Examples:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The ODPI-C constant DPI_MODE_AUTH_SYSDBA becomes ORA_MODE_AUTH_SYSDBA in Julia.\nThe ODPI-C enum dpiAuthMode becomes OraAuthMode in Julia.\nThe ODPI-C struct dpiTimestamp becomes OraTimestamp in Julia.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"All julia structs with prefix Ora are raw wrappers around ODPC-C structs and may contain unsafe attributes.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Safe equivalent Julia structs drop the Ora prefix.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"ODPI-C function wrappers have their name preserved, as in dpiContext_create.","category":"page"},{"location":"#License-1","page":"Home","title":"License","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"The source code for the package Oracle.jl is licensed under the MIT License.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"During installation, Oracle.jl downloads the source code and compile the library ODPI-C which is licensed under The Universal Permissive License (UPL), Version 1.0 and/or the Apache License.","category":"page"},{"location":"tutorial/#Tutorial-1","page":"Tutorial","title":"Tutorial","text":"","category":"section"},{"location":"tutorial/#Getting-a-Connection-1","page":"Tutorial","title":"Getting a Connection","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"import Oracle\n\nusername = \"my_username\"\npassword = \"my_password\"\nconnect_string = \"//IP_ADDRESS/XE\" # a valid Oracle connect string\n\nconn = Oracle.Connection(username, password, connect_string)","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Currently, this driver only supports connections using ASCII or UTF-8 encodings. All connections are created using UTF-8 encoding by default, for both CHAR and NCHAR.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"To connect as SYSDBA, use the appropriate auth_mode parameter.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"conn = Oracle.Connection(username, password, connect_string, auth_mode=Oracle.ORA_MODE_AUTH_SYSDBA)","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"You should always close connections using Oracle.close method.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Oracle.close(conn)","category":"page"},{"location":"tutorial/#Executing-a-Statement-1","page":"Tutorial","title":"Executing a Statement","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_TEST ( ID INT NULL )\")\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( 1 )\")\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( null )\")\nOracle.commit(conn) # will commit 2 lines\n\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( 3 )\")\nOracle.rollback(conn) # abort insertion of the third line","category":"page"},{"location":"tutorial/#Binding-values-to-a-Statement-1","page":"Tutorial","title":"Binding values to a Statement","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_BIND ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)\")\n\n# get an explicit reference to a statement\nstmt = Oracle.Stmt(conn, \"INSERT INTO TB_BIND ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )\")\n\n# will add a single line to TB_BIND\nstmt[:id] = 1\nstmt[:flt] = 10.23\nstmt[:str] = \"a string\"\nstmt[:dt] = Date(2018,12,31)\nOracle.execute(stmt)\n\nOracle.commit(conn)\nOracle.close(stmt)","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Whenever you get an explicit reference to a statement, you should always use Oracle.close method when you're done with it.","category":"page"},{"location":"tutorial/#Executing-a-Query-1","page":"Tutorial","title":"Executing a Query","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Use Oracle.query to execute a query. It returns a ResultSet, which is a table-like struct. All data is fetched from the statement before returning the ResultSet.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"rs = Oracle.query(conn, \"SELECT ID, FLT, STR, DT FROM TB_BIND\")\n\nprintln(rs[2, 1]) # will print the element at row 2, column 1.\nprintln(rs[2, \"ID\"]) # will print element at row 2, column ID (same as column 1).\nprintln(rs[:, 1]) # will print all the elements in column 1.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"The last example was easy to use, but maybe your memory can't hold all the data in the ResultSet. Use Oracle.query method with do-syntax to get a reference to a cursor, which will fetch one row at a time.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Oracle.query(conn, \"SELECT * FROM TB_BIND\") do cursor\n    for row in cursor\n        # row values can be accessed using column name or position\n        println( row[\"ID\"]  ) # same as row[1]\n        println( row[\"FLT\"] )\n        println( row[\"STR\"] )\n        println( row[\"DT\"]  ) # same as row[4]\n    end\nend","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"You can also use a prepared statement to execute a query.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"stmt = Oracle.Stmt(conn, \"SELECT FLT FROM TB_BIND WHERE ID = :id\")\nstmt[:id] = 1\n\nOracle.query(stmt) do cursor\n    for row in cursor\n      println(row[\"FLT\"])\n    end\nend\n\nOracle.close(stmt)","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"There is also the possibility to fetch one row at a time manually, with a small overhead when compared to previous methods.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"stmt = Oracle.Stmt(conn, \"SELECT FLT FROM TB_BIND\")\nOracle.execute(stmt)\n\nrow = Oracle.fetchrow(stmt)\nwhile row != nothing\n    println(row[1])\n    row = Oracle.fetchrow(stmt)\nend\n\nOracle.close(stmt)","category":"page"},{"location":"tutorial/#Batch-statement-execution-1","page":"Tutorial","title":"Batch statement execution","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"If you need to execute the same statement many times but binding different values each time, pass a vector of columns to Oracle.execute method.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"This will use the ODPI-C executeMany feature.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"NUM_ROWS = 1_000\n\ncolumn_1 = [ i for i in 1:NUM_ROWS ]\ncolumn_2 = .5 * column_1\n\nsql = \"INSERT INTO TB_BENCH_EXECUTE_MANY ( ID, FLT ) VALUES ( :1, :2 )\"\nOracle.execute(conn, sql, [ column_1, column_2 ])","category":"page"},{"location":"tutorial/#Session-Pools-1","page":"Tutorial","title":"Session Pools","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"A Pool represents a pool of connections, and provides a faster way to acquire connections to the database.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"# creates a pool for a maximum of 2 sessions\npool = Oracle.Pool(username, password, connect_string, max_sessions=2, session_increment=1)\n\nconn_1 = Oracle.Connection(pool)\nconn_2 = Oracle.Connection(pool) # at this point, we can't acquire more connections\n\n# release a connection so that we can acquire another one.\nOracle.close(conn_1)\n\n# by now, acquiring a new connection should be pretty fast\n# since the new connection will be taken from the pool\nconn_3 = Oracle.Connection(pool)\n\n# release all connections that are still open\nOracle.close(conn_2)\nOracle.close(conn_3)\n\nOracle.close(pool)","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"You should always close Pools using Oracle.close method.","category":"page"},{"location":"tutorial/#LOB-1","page":"Tutorial","title":"LOB","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Oracle LOB fields can hold up to 4GB of data.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"They come in two flavors:","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Binary LOBs: BLOB or BFILE.\nCharacter LOBs: CLOB or NCLOB.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"LOB values are represented as a value of type Oracle.Lob in this package.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"From a LOB value, you can use read and write methods to manipulate whole contents of the LOB value. For incremental reading/writing, you can use open with do-syntax do get an IO stream out of a Oracle.Lob.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"IO Streams created on Character LOBs use the character index as its position, and only support reading/writing for Char and String data types.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"You should always close a LOB using Oracle.close method.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Currently, BFILE is not supported.","category":"page"},{"location":"tutorial/#Reading-from-a-BLOB-1","page":"Tutorial","title":"Reading from a BLOB","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"lyric = \"hey you. 🎵 🎶 Out there in the cold. getting lonely, getting old. Can you feel me? 📼📼📼📼\"\n\nOracle.execute(conn, \"CREATE TABLE TB_BLOB ( b BLOB )\")\nOracle.execute(conn, \"INSERT INTO TB_BLOB ( B ) VALUES ( utl_raw.cast_to_raw('$lyric'))\")\n\nOracle.query(conn, \"SELECT B FROM TB_BLOB\") do cursor\n    for row in cursor\n        blob = row[\"B\"]\n        bytes_vector = read(blob) # Vector{UInt8}\n        println(String(bytes_vector))\n    end\nend","category":"page"},{"location":"tutorial/#Writing-to-a-BLOB-1","page":"Tutorial","title":"Writing to a BLOB","text":"","category":"section"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Follow these steps to write to a BLOB field in the database.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Create a temporary Lob associated with the connection using Oracle.Lob(connection, oracle_type).\nWrite data to the Lob.\nWrap the Lob into a Variable.\nBind the variable to the statement.\nExecute the statement.","category":"page"},{"location":"tutorial/#","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_BLOB_VARIABLE ( B BLOB )\")\n\ntest_data = rand(UInt8, 5000)\n\n# creates a temporary Lob bounded to the Connection\nblob = Oracle.Lob(conn, Oracle.ORA_ORACLE_TYPE_BLOB)\n\n# replaces all Lob data with the contents of the array test_data\nwrite(blob, test_data)\n\n# wraps the blob in a Variable\nora_var = Oracle.Variable(conn, blob)\n\nstmt = Oracle.Stmt(conn, \"INSERT INTO TB_BLOB_VARIABLE ( B ) VALUES ( :1 )\")\n\n# binds the variable to the statement\nstmt[1] = ora_var\n\nOracle.execute(stmt)\nOracle.close(stmt)","category":"page"},{"location":"api/#API-Reference-1","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"api/#","page":"API Reference","title":"API Reference","text":"Modules = [Oracle]","category":"page"},{"location":"api/#Oracle.AbstractOracleValue","page":"API Reference","title":"Oracle.AbstractOracleValue","text":"Holds a 1-indexed vector of OraData.\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.CommonCreateParams","page":"API Reference","title":"Oracle.CommonCreateParams","text":"Safe version of OraCommonCreateParams\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.ConnCreateParams","page":"API Reference","title":"Oracle.ConnCreateParams","text":"Safe version of OraConnCreateParams\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.Connection","page":"API Reference","title":"Oracle.Connection","text":"Connection handles are used to represent connections to the database. These can be standalone connections created by calling the function dpiConncreate() or acquired from a session pool by calling the function dpiPoolacquireConnection(). They can be closed by calling the function dpiConnclose() or releasing the last reference to the connection by calling the function dpiConnrelease(). Connection handles are used to create all handles other than session pools and context handles.\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.EncodingInfo","page":"API Reference","title":"Oracle.EncodingInfo","text":"Mirrors ODPI-C's OraEncodingInfo struct, but using Julia types.\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.ExternOracleValue","page":"API Reference","title":"Oracle.ExternOracleValue","text":"Wraps a OraData handle managed by extern ODPI-C. 1-indexed.\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.JuliaOracleValue","page":"API Reference","title":"Oracle.JuliaOracleValue","text":"Wraps a OraData handle managed by Julia. 1-indexed.\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.OraCommonCreateParams-Tuple{Oracle.Context,Oracle.CommonCreateParams}","page":"API Reference","title":"Oracle.OraCommonCreateParams","text":"This function may be unsafe: safe_params must outlive the OraCommonCreateParams generated by this function.\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.OraConnCreateParams-Tuple{Oracle.Context,Oracle.ConnCreateParams}","page":"API Reference","title":"Oracle.OraConnCreateParams","text":"This function may be unsafe: safe_params must outlive the OraConnCreateParams generated by this function.\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.StmtInfo","page":"API Reference","title":"Oracle.StmtInfo","text":"High-level version for OraStmtInfo using Bool Julia type.\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.Variable-Union{Tuple{T}, Tuple{Connection,Type{T},OraOracleTypeNum,OraNativeTypeNum}} where T","page":"API Reference","title":"Oracle.Variable","text":"Variable is a 1-indexed array of OraData.\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.define-Tuple{Oracle.Stmt{ORA_STMT_TYPE_SELECT::OraStatementType = 0x0001},Integer,Oracle.Variable}","page":"API Reference","title":"Oracle.define","text":"define(stmt::QueryStmt, column_position::Integer, variable::Variable)\n\nDefines the variable that will be used to fetch rows from the statement. stmt must be an executed statement.\n\nA Variable v bound to a statement stmt must satisfy:\n\nv.buffer_capacity >= fetch_array_size(stmt)\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.execute-Tuple{Oracle.Stmt}","page":"API Reference","title":"Oracle.execute","text":"execute(stmt::Stmt; exec_mode::dpiExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32\n\nReturns the number of columns which are being queried. If the statement does not refer to a query, the value is set to 0.\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.fetch-Tuple{Oracle.Stmt}","page":"API Reference","title":"Oracle.fetch","text":"fetch(stmt::Stmt) :: FetchResult\n\nFetches a single row from the statement.\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.fetch_array_size!-Tuple{Oracle.Stmt,Integer}","page":"API Reference","title":"Oracle.fetch_array_size!","text":"fetch_array_size!(stmt::Stmt, new_size::Integer)\n\nSets the array size used for performing fetches. All variables defined for fetching must have this many (or more) elements allocated for them. The higher this value is the less network round trips are required to fetch rows from the database but more memory is also required.\n\nA value of zero will reset the array size to the default value of DPIDEFAULTFETCHARRAYSIZE.\n\n\n\n\n\n","category":"method"},{"location":"api/#Oracle.row_count-Tuple{Oracle.Stmt}","page":"API Reference","title":"Oracle.row_count","text":"Number of affected rows in a DML statement.\n\n\n\n\n\n","category":"method"}]
}
