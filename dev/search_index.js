var documenterSearchIndex = {"docs":
[{"location":"api/#API-Reference","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"api/#ODPI-C-Naming-Conventions","page":"API Reference","title":"ODPI-C Naming Conventions","text":"","category":"section"},{"location":"api/","page":"API Reference","title":"API Reference","text":"All enums, constants and structs in ODPI-C library use the prefix DPI or dpi.","category":"page"},{"location":"api/","page":"API Reference","title":"API Reference","text":"In Oracle.jl, the Julia implementation of these elements use the prefix ORA or Ora.","category":"page"},{"location":"api/","page":"API Reference","title":"API Reference","text":"Examples:","category":"page"},{"location":"api/","page":"API Reference","title":"API Reference","text":"The ODPI-C constant DPI_MODE_AUTH_SYSDBA becomes ORA_MODE_AUTH_SYSDBA in Julia.\nThe ODPI-C enum dpiAuthMode becomes OraAuthMode in Julia.\nThe ODPI-C struct dpiTimestamp becomes OraTimestamp in Julia.","category":"page"},{"location":"api/","page":"API Reference","title":"API Reference","text":"All julia structs with prefix Ora are raw wrappers around ODPC-C structs and may contain unsafe attributes.","category":"page"},{"location":"api/","page":"API Reference","title":"API Reference","text":"Safe equivalent Julia structs drop the Ora prefix.","category":"page"},{"location":"api/","page":"API Reference","title":"API Reference","text":"ODPI-C function wrappers have their name preserved, as in dpiContext_create.","category":"page"},{"location":"api/#Connection","page":"API Reference","title":"Connection","text":"","category":"section"},{"location":"api/","page":"API Reference","title":"API Reference","text":"Oracle.Connection\nOracle.ping\nOracle.commit\nOracle.rollback\nOracle.set_client_identifier\nOracle.set_client_info","category":"page"},{"location":"api/#Oracle.Connection","page":"API Reference","title":"Oracle.Connection","text":"Connection(user::AbstractString, password::AbstractString, connect_string::AbstractString;\n        encoding::AbstractString=DEFAULT_CONNECTION_ENCODING,\n        nencoding::AbstractString=DEFAULT_CONNECTION_NENCODING,\n        create_mode::Union{Nothing, OraCreateMode}=nothing,\n        edition::Union{Nothing, String}=nothing,\n        driver_name::Union{Nothing, String}=nothing,\n        auth_mode::OraAuthMode=ORA_MODE_AUTH_DEFAULT,\n        pool::Union{Nothing, Pool}=nothing\n    )\n\nCreates a connection to the Oracle Database.\n\nConnections should always be closed after use by calling Oracle.close.\n\nExample\n\nimport Oracle\n\nusername = \"my_username\"\npassword = \"my_password\"\nconnect_string = \"//IP_ADDRESS/XE\" # a valid Oracle connect string\n\nconn = Oracle.Connection(username, password, connect_string)\n\n# connections should always be closed after use.\nOracle.close(conn)\n\n\n\n\n\n","category":"type"},{"location":"api/#Oracle.ping","page":"API Reference","title":"Oracle.ping","text":"ping(conn::Connection)\n\nPings the database server to check if the connection is still alive. Throws error if can't ping the server.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.commit","page":"API Reference","title":"Oracle.commit","text":"commit(conn::Connection)\n\nCommits the current active transaction.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.rollback","page":"API Reference","title":"Oracle.rollback","text":"rollback(conn::Connection)\n\nRolls back the current active transaction.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.set_client_identifier","page":"API Reference","title":"Oracle.set_client_identifier","text":"set_client_identifier(conn::Connection, client_identifier::AbstractString)\n\nSets the CLIENT_IDENTIFIER attribute on the connection. This is useful for audit trails and database triggers.\n\nThe following query can be used to retrieve this attribute.\n\nSELECT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') CTX_CLIENT_IDENTIFIER FROM DUAL\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.set_client_info","page":"API Reference","title":"Oracle.set_client_info","text":"set_client_info(conn::Connection, client_info::AbstractString)\n\nSets the CLIENT_INFO attribute on the connection. This is useful for audit trails and database triggers.\n\nThe following query can be used to retrieve this attribute.\n\nSELECT SYS_CONTEXT('USERENV', 'CLIENT_INFO') CTX_CLIENT_INFO FROM DUAL\n\n\n\n\n\n","category":"function"},{"location":"api/#Statement","page":"API Reference","title":"Statement","text":"","category":"section"},{"location":"api/","page":"API Reference","title":"API Reference","text":"Oracle.execute\nOracle.row_count\nOracle.fetch_array_size!\nOracle.fetch","category":"page"},{"location":"api/#Oracle.execute","page":"API Reference","title":"Oracle.execute","text":"execute(stmt::Stmt; exec_mode::dpiExecMode=ORA_MODE_EXEC_DEFAULT) :: UInt32\n\nReturns the number of columns which are being queried. If the statement does not refer to a query, the value is set to 0.\n\n\n\n\n\nexecute(connection::Connection, sql::AbstractString;\n    scrollable::Bool=false,\n    tag::AbstractString=\"\",\n    exec_mode::OraExecMode=ORA_MODE_EXEC_DEFAULT\n) :: UInt32\n\nExecute a single sql statement.\n\nReturns the number of columns which are being queried. If the statement does not refer to a query, the value is set to 0.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.row_count","page":"API Reference","title":"Oracle.row_count","text":"Number of affected rows in a DML statement.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.fetch_array_size!","page":"API Reference","title":"Oracle.fetch_array_size!","text":"fetch_array_size!(stmt::Stmt, new_size::Integer)\n\nSets the array size used for performing fetches. All variables defined for fetching must have this many (or more) elements allocated for them. The higher this value is the less network round trips are required to fetch rows from the database but more memory is also required.\n\nA value of zero will reset the array size to the default value of DPIDEFAULTFETCHARRAYSIZE.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.fetch","page":"API Reference","title":"Oracle.fetch","text":"fetch(stmt::Stmt) :: FetchResult\n\nFetches a single row from the statement.\n\n\n\n\n\n","category":"function"},{"location":"api/#Variable","page":"API Reference","title":"Variable","text":"","category":"section"},{"location":"api/","page":"API Reference","title":"API Reference","text":"Oracle.get_returned_data\nOracle.define","category":"page"},{"location":"api/#Oracle.get_returned_data","page":"API Reference","title":"Oracle.get_returned_data","text":"get_returned_data(variable::Variable, pos::Integer) :: Vector\n\nCollects all the data bounded to variable at position pos being transfered to and from the database.\n\n\n\n\n\n","category":"function"},{"location":"api/#Oracle.define","page":"API Reference","title":"Oracle.define","text":"define(stmt::QueryStmt, column_position::Integer, variable::Variable)\n\nDefines the variable that will be used to fetch rows from the statement. stmt must be an executed statement.\n\nA Variable v bound to a statement stmt must satisfy:\n\nv.buffer_capacity >= fetch_array_size(stmt)\n\n\n\n\n\n","category":"function"},{"location":"api/#Lob","page":"API Reference","title":"Lob","text":"","category":"section"},{"location":"api/","page":"API Reference","title":"API Reference","text":"Oracle.chunk_size","category":"page"},{"location":"api/#Oracle.chunk_size","page":"API Reference","title":"Oracle.chunk_size","text":"chunk_size(lob::Lob) :: UInt32\n\nReturns the chunk size, in bytes, of the internal LOB. Reading and writing to the LOB in multiples of this size will improve performance.\n\n\n\n\n\n","category":"function"},{"location":"#Oracle.jl","page":"Home","title":"Oracle.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package provides a driver to access Oracle databases using the Julia language, based on ODPI-C bindings.","category":"page"},{"location":"#Requirements","page":"Home","title":"Requirements","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Julia v1.0 or newer.\nOracle's Instant Client.\nLinux or macOS.\nC compiler.","category":"page"},{"location":"#Instant-Client-installation","page":"Home","title":"Instant Client installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package requires Oracle's Instant Client.","category":"page"},{"location":"","page":"Home","title":"Home","text":"To install it, follow these instructions:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Download instant client.\nUnzip and add instantclient folder to your LD_LIBRARY_PATH:","category":"page"},{"location":"","page":"Home","title":"Home","text":"export LD_LIBRARY_PATH=/path-to-folder/instantclient:$LD_LIBRARY_PATH","category":"page"},{"location":"","page":"Home","title":"Home","text":"Check ODPI-C documentation, or Instant Client documentation for alternative installation methods.","category":"page"},{"location":"","page":"Home","title":"Home","text":"libaio is a dependency of Instant Client.","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you have root access to your machine, you can install it using the package manager, as in:","category":"page"},{"location":"","page":"Home","title":"Home","text":"yum -y install libaio","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you don't have root access to your machine, you can compile it from source and set your LD_LIBRARY_PATH environment variable to point to the library.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The compilation can be done using the following script:","category":"page"},{"location":"","page":"Home","title":"Home","text":"wget https://pagure.io/libaio/archive/libaio-0.3.111/libaio-libaio-0.3.111.tar.gz\ntar xf libaio-libaio-0.3.111.tar.gz\ncd libaio-libaio-0.3.111\nmake prefix=$HOME/local\nmake install prefix=$HOME/local","category":"page"},{"location":"","page":"Home","title":"Home","text":"Then add the following to your shell profile ($HOME/.bashrc):","category":"page"},{"location":"","page":"Home","title":"Home","text":"export LD_LIBRARY_PATH=$HOME/local/lib:$LD_LIBRARY_PATH","category":"page"},{"location":"#Package-installation","page":"Home","title":"Package installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"julia> Pkg.add(\"Oracle\")","category":"page"},{"location":"#Installation-on-Jupyter-environment","page":"Home","title":"Installation on Jupyter environment","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"When loading this package on a Jupyter Notebook environment you might get this error:","category":"page"},{"location":"","page":"Home","title":"Home","text":"InitError: DPI-1047: Cannot locate a 64-bit Oracle Client library: \"libclntsh.so: cannot open shared object file: No such file or directory\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"First, check that the package loads outside the Jupyter environment. If it does work, than the problem is that LD_LIBRARY_PATH is not set in the Jupyter environment.","category":"page"},{"location":"","page":"Home","title":"Home","text":"To solve this, edit your kernel.json file, usually located at ~/.local/share/jupyter/kernels/julia-v where v is the Julia version, and add an environment variable for your LD_LIBRARY_PATH, as in the following example, where /myhomedir/local/instantclient is the location for the instant client library.","category":"page"},{"location":"","page":"Home","title":"Home","text":"{\n  \"display_name\": \"Julia 1.1.0\",\n  \"argv\": [\n    \"env\",\n    \"LD_LIBRARY_PATH=/myhomedir/local/instantclient\",\n    \"/myhomedir/local/julia-1.1.0/bin/julia\",\n    \"-i\",\n    \"--startup-file=yes\",\n    \"--color=yes\",\n    \"--project=@.\",\n    \"/myhomedir/.julia/packages/IJulia/gI2uA/src/kernel.jl\",\n    \"{connection_file}\"\n  ],\n  \"language\": \"julia\",\n  \"env\": {},\n  \"interrupt_mode\": \"signal\"\n}","category":"page"},{"location":"","page":"Home","title":"Home","text":"The LD_LIBRARY_PATH environment variable must be set before the Julia process starts. This is why you can't just set this variable inside the Jupyter notebook.","category":"page"},{"location":"#Source-Code","page":"Home","title":"Source Code","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The source code for this package is hosted at https://github.com/felipenoris/Oracle.jl.","category":"page"},{"location":"#License","page":"Home","title":"License","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The source code for the package Oracle.jl is licensed under the MIT License.","category":"page"},{"location":"","page":"Home","title":"Home","text":"During installation, Oracle.jl downloads the source code and compiles the library ODPI-C which is licensed under The Universal Permissive License (UPL), Version 1.0 and/or the Apache License.","category":"page"},{"location":"tutorial/#Tutorial","page":"Tutorial","title":"Tutorial","text":"","category":"section"},{"location":"tutorial/#Getting-a-Connection","page":"Tutorial","title":"Getting a Connection","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"import Oracle\n\nusername = \"my_username\"\npassword = \"my_password\"\nconnect_string = \"//IP_ADDRESS/XE\" # a valid Oracle connect string\n\nconn = Oracle.Connection(username, password, connect_string)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Currently, this driver only supports connections using ASCII or UTF-8 encodings. All connections are created using UTF-8 encoding by default, for both CHAR and NCHAR data types.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"To connect as SYSDBA, use the appropriate auth_mode parameter.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"conn = Oracle.Connection(username, password, connect_string, auth_mode=Oracle.ORA_MODE_AUTH_SYSDBA)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You should always close connections using Oracle.close method.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.close(conn)","category":"page"},{"location":"tutorial/#Executing-a-Statement","page":"Tutorial","title":"Executing a Statement","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_TEST ( ID INT NULL )\")\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( 1 )\")\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( null )\")\nOracle.commit(conn) # will commit 2 lines\n\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( 3 )\")\nOracle.rollback(conn) # abort insertion of the third line","category":"page"},{"location":"tutorial/#Binding-values-to-a-Statement","page":"Tutorial","title":"Binding values to a Statement","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_BIND ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)\")\n\n# get an explicit reference to a statement\nstmt = Oracle.Stmt(conn, \"INSERT INTO TB_BIND ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )\")\n\n# will add a single line to TB_BIND\nstmt[:id] = 1\nstmt[:flt] = 10.23\nstmt[:str] = \"a string\"\nstmt[:dt] = Date(2018,12,31)\nOracle.execute(stmt)\n\nOracle.commit(conn)\nOracle.close(stmt)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Whenever you get an explicit reference to a statement, you should always use Oracle.close method when you're done with it.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The next example constructs a Statement using the do-syntax, that automatically closes the statement at the end. It also shows how to bind values by position.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.stmt(conn, \"INSERT INTO TB_BIND ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )\") do stmt\n    stmt[1] = 1\n    stmt[2] = 10.1234\n    stmt[3] = \"this is a string\"\n    stmt[4, Date] = missing # we must inform the type when setting value as missing\n\n    Oracle.execute(stmt)\n    Oracle.commit(conn)\nend","category":"page"},{"location":"tutorial/#Executing-a-Query","page":"Tutorial","title":"Executing a Query","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Use Oracle.query to execute a query. It returns a ResultSet, which is a table-like struct. All data is fetched from the statement before returning the ResultSet.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"rs = Oracle.query(conn, \"SELECT ID, FLT, STR, DT FROM TB_BIND\")\n\nprintln(names(rs)) # print column names\nprintln(rs[2, 1]) # will print the element at row 2, column 1.\nprintln(rs[2, \"ID\"]) # will print element at row 2, column ID (same as column 1).\nprintln(rs[:, 1]) # will print all the elements in column 1.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The last example was easy to use, but maybe your memory can't hold all the data in the ResultSet.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"ResultSet implements Tables.jl interface. That means that you can transform it into a DataFrame.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using DataFrames\nrs = Oracle.query(conn, \"SELECT ID, FLT, STR, DT FROM TB_BIND\")\nprintln(DataFrame(rs))","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Use Oracle.query method with do-syntax to get a reference to a cursor, which will fetch one row at a time.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.query(conn, \"SELECT * FROM TB_BIND\") do cursor\n\n    # prints column names\n    println(names(cursor))\n\n    for row in cursor\n        # row values can be accessed using column name or position\n        println( row[\"ID\"]  ) # same as row[1]\n        println( row[\"FLT\"] )\n        println( row[\"STR\"] )\n        println( row[\"DT\"]  ) # same as row[4]\n    end\nend","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can also use a prepared statement to execute a query.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"stmt = Oracle.Stmt(conn, \"SELECT FLT FROM TB_BIND WHERE ID = :id\")\nstmt[:id] = 1\n\nOracle.query(stmt) do cursor\n    for row in cursor\n      println(row[\"FLT\"])\n    end\nend\n\nOracle.close(stmt)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"There is also the possibility to fetch one row at a time manually, with a small overhead when compared to previous methods.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"stmt = Oracle.Stmt(conn, \"SELECT FLT FROM TB_BIND\")\nOracle.execute(stmt)\n\nrow = Oracle.fetchrow(stmt)\nwhile row != nothing\n    println(row[1])\n    row = Oracle.fetchrow(stmt)\nend\n\nOracle.close(stmt)","category":"page"},{"location":"tutorial/#Batch-statement-execution","page":"Tutorial","title":"Batch statement execution","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"If you need to execute the same statement many times but binding different values each time, pass a vector of columns to Oracle.execute method.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"This will use the ODPI-C executeMany feature.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"NUM_ROWS = 1_000\n\ncolumn_1 = [ i for i in 1:NUM_ROWS ]\ncolumn_2 = .5 * column_1\n\nsql = \"INSERT INTO TB_BENCH_EXECUTE_MANY ( ID, FLT ) VALUES ( :1, :2 )\"\nOracle.execute_many(conn, sql, [ column_1, column_2 ])","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"It is also possible to bind input and output variables in one go. The following example shows how to insert data to a table that generates keys with a sequence, returning the keys that were created.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_EXEC_MANY_INOUT ( ID NUMBER(15, 0) NOT NULL, STR VARCHAR2(4000), LB BLOB NOT NULL )\")\nOracle.execute(conn, \"ALTER TABLE TB_EXEC_MANY_INOUT ADD CONSTRAINT XPK_TB_EXEC_MANY_INOUT PRIMARY KEY (ID)\")\nOracle.execute(conn, \"CREATE SEQUENCE SQ_TB_EXEC_MANY_INOUT INCREMENT BY 1  START WITH 1001\")\n\ninput_data = [\"input1\", \"input2\", \"input3\"]\nnum_iters = length(input_data)\nvar_input = Oracle.Variable(conn, input_data)\n\n# example of BLOB variables\nblob_data = [ rand(UInt8, 5000) for i in 1:num_iters ]\nblobs = [ Oracle.Lob(conn, Oracle.ORA_ORACLE_TYPE_BLOB) for i in 1:num_iters ]\nfor i in 1:num_iters\n    write(blobs[i], blob_data[i])\nend\nvar_blob = Oracle.Variable(conn, blobs)\n\nvar_output = Oracle.Variable(conn, Int, buffer_capacity=num_iters)\n\nvars = Dict(:var_input => var_input, :var_blob => var_blob, :var_output => var_output)\n\nstmt = Oracle.Stmt(conn, \"INSERT INTO TB_EXEC_MANY_INOUT ( ID, STR, LB ) VALUES ( SQ_TB_EXEC_MANY_INOUT.nextval, :var_input, :var_blob ) RETURNING ID INTO :var_output\")\ntry\n    Oracle.execute_many(stmt, num_iters, vars)\n    Oracle.commit(conn)\n\n    Oracle.query(conn, \"SELECT ID, STR, LB FROM TB_EXEC_MANY_INOUT ORDER BY ID\") do cursor\n        i = 1\n        for row in cursor\n            @test parse(Int, row[\"STR\"][end]) + 1000 == row[\"ID\"]\n            @test row[\"ID\"] == Oracle.get_returned_data(var_output, i)[1]\n            @test read(row[\"LB\"]) == blob_data[i]\n            i += 1\n        end\n    end\n\n    for i in 1:num_iters\n        @test Oracle.get_returned_data(var_output, i)[1] == 1000 + i\n    end\n\nfinally\n    Oracle.close(stmt)\n    Oracle.execute(conn, \"DROP SEQUENCE SQ_TB_EXEC_MANY_INOUT\")\n    Oracle.execute(conn, \"DROP TABLE TB_EXEC_MANY_INOUT\")\nend","category":"page"},{"location":"tutorial/#Session-Pools","page":"Tutorial","title":"Session Pools","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"A Pool represents a pool of connections, and provides a faster way to acquire connections to the database.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"# creates a pool for a maximum of 2 sessions\npool = Oracle.Pool(username, password, connect_string, max_sessions=2, session_increment=1)\n\nconn_1 = Oracle.Connection(pool)\nconn_2 = Oracle.Connection(pool) # at this point, we can't acquire more connections\n\n# release a connection so that we can acquire another one.\nOracle.close(conn_1)\n\n# by now, acquiring a new connection should be pretty fast\n# since the new connection will be taken from the pool\nconn_3 = Oracle.Connection(pool)\n\n# release all connections that are still open\nOracle.close(conn_2)\nOracle.close(conn_3)\n\nOracle.close(pool)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You should always close Pools using Oracle.close method.","category":"page"},{"location":"tutorial/#LOB","page":"Tutorial","title":"LOB","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle LOB fields can hold up to 4GB of data.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"They come in two flavors:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Binary LOBs: BLOB or BFILE.\nCharacter LOBs: CLOB or NCLOB.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"LOB values are represented as a value of type Oracle.Lob in this package.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"From a LOB value, you can use read and write methods to manipulate whole contents of the LOB value. For incremental reading/writing, you can use open with do-syntax do get an IO stream out of a Oracle.Lob.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"IO Streams created on Character LOBs use the character index as its position, and only support reading/writing for Char and String data types.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You should always close a LOB using Oracle.close method.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Currently, BFILE is not supported.","category":"page"},{"location":"tutorial/#Reading-from-a-BLOB","page":"Tutorial","title":"Reading from a BLOB","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"lyric = \"hey you. 🎵 🎶 Out there in the cold. getting lonely, getting old. Can you feel me? 📼📼📼📼\"\n\nOracle.execute(conn, \"CREATE TABLE TB_BLOB ( b BLOB )\")\nOracle.execute(conn, \"INSERT INTO TB_BLOB ( B ) VALUES ( utl_raw.cast_to_raw('$lyric'))\")\n\nOracle.query(conn, \"SELECT B FROM TB_BLOB\") do cursor\n    for row in cursor\n        blob = row[\"B\"]\n        bytes_vector = read(blob) # Vector{UInt8}\n        println(String(bytes_vector))\n    end\nend","category":"page"},{"location":"tutorial/#Writing-to-a-BLOB","page":"Tutorial","title":"Writing to a BLOB","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Follow these steps to write to a BLOB field in the database.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Create a temporary Lob associated with the connection using Oracle.Lob(connection, oracle_type).\nWrite data to the Lob.\nWrap the Lob into a Variable.\nBind the variable to the statement.\nExecute the statement.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"CREATE TABLE TB_BLOB_VARIABLE ( B BLOB )\")\n\ntest_data = rand(UInt8, 5000)\n\n# creates a temporary Lob bounded to the Connection\nblob = Oracle.Lob(conn, Oracle.ORA_ORACLE_TYPE_BLOB)\n\n# replaces all Lob data with the contents of the array test_data\nwrite(blob, test_data)\n\n# wraps the blob in a Variable\nora_var = Oracle.Variable(conn, blob)\n\nstmt = Oracle.Stmt(conn, \"INSERT INTO TB_BLOB_VARIABLE ( B ) VALUES ( :1 )\")\n\n# binds the variable to the statement\nstmt[1] = ora_var\n\nOracle.execute(stmt)\nOracle.close(stmt)","category":"page"},{"location":"tutorial/#Transactions","page":"Tutorial","title":"Transactions","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The way Oracle Database works, “a transaction in Oracle begins when the first executable SQL statement is encountered”.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Use Oracle.commit to commit and Oracle.rollback to abort a transaction.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The following example is a valid transaction.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Oracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( 1 )\") # will start a transaction\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( null )\")\nOracle.commit(conn) # will commit 2 lines\n\nOracle.execute(conn, \"INSERT INTO TB_TEST ( ID ) VALUES ( 3 )\") # will start a new transaction\nOracle.rollback(conn) # abort insertion of the third line","category":"page"}]
}
