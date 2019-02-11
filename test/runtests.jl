
include("timestamps_tests.jl")

import Oracle

if VERSION < v"0.7-"
    using Base.Test
    using Missings
else
    using Test
    using Dates
end

@testset "subtract_missing" begin
    @test Oracle.subtract_missing(Float64) == Float64
    @test_throws AssertionError Oracle.subtract_missing(Missing)
    @test Oracle.subtract_missing(Union{Missing, Float64}) == Float64
    @test Oracle.subtract_missing(Union{Float64, Missing}) == Float64
    @test_throws ErrorException Oracle.subtract_missing(Union{Int, Union{Float64, Missing}})
end

@assert isfile(joinpath(@__DIR__, "credentials.jl")) """
Before running tests, create a file `test/credentials.jl` with the content:

username = "your-username"
password = "your-password"
connect_string = "your-connect-string"
auth_mode = Oracle.ORA_MODE_AUTH_DEFAULT # or Oracle.ORA_MODE_AUTH_SYSDBA if user is SYSDBA
"""
include("credentials.jl")

conn = Oracle.Connection(username, password, connect_string, auth_mode=auth_mode)

# Client Version
let
    v = Oracle.client_version(Oracle.Context())
    println("")
    println("### CLIENT VERSION ###")
    println(v)
end

# Server Version
let
    release, server_version = Oracle.server_version(conn)
    println("### SERVER VERSION ###")
    println("release = $release")
    println("server_version = $server_version")
end

# Database Encoding
let
    Oracle.query(conn, "select value from nls_database_parameters where parameter='NLS_CHARACTERSET'") do cursor
        for row in cursor
            println("Database NLS_CHARACTERSET = ", row["VALUE"])
        end
    end
end

# Connection Encoding Info
let
    println("Connection encoding info: ", conn.encoding_info)
end

# Current Schema
println("Current Schema: ", Oracle.current_schema(conn))

println("")

@testset "connection" begin

    @testset "ping" begin
        Oracle.ping(conn)
    end

    @testset "stmt cache size" begin
        original_cache_size = Oracle.stmt_cache_size(conn)

        new_cache_size = 5
        Oracle.stmt_cache_size!(conn, new_cache_size)
        @test Oracle.stmt_cache_size(conn) == new_cache_size

        Oracle.stmt_cache_size!(conn, original_cache_size)
        @test Oracle.stmt_cache_size(conn) == original_cache_size
    end

    @testset "Supported encodings" begin
        for enc in Oracle.SUPPORTED_CONNECTION_ENCODINGS
            conn_enc = Oracle.Connection(username, password, connect_string, auth_mode=auth_mode, encoding=enc, nencoding=enc)
            Oracle.close!(conn_enc)
        end
    end
end

@testset "query/commit/rollback" begin
    Oracle.execute!(conn, "CREATE TABLE TB_TEST ( ID INT NULL )")
    Oracle.execute!(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 1 )")
    Oracle.execute!(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( null )")
    Oracle.commit!(conn)

    Oracle.execute!(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 3 )")
    Oracle.rollback!(conn)
end

@testset "Stmt" begin
    stmt = Oracle.Stmt(conn, "SELECT * FROM TB_TEST")
    @test stmt.bind_count == 0

    @test stmt.info.is_query
    @test !stmt.info.is_DDL
    @test !stmt.info.is_DML
    @test stmt.info.statement_type == Oracle.ORA_STMT_TYPE_SELECT

    @testset "fetch size" begin
        @test Oracle.fetch_array_size(stmt) == Oracle.ORA_DEFAULT_FETCH_ARRAY_SIZE

        Oracle.fetch_array_size!(stmt, 150)
        @test Oracle.fetch_array_size(stmt) == 150
    end

    Oracle.execute!(stmt)
    @test Oracle.num_columns(stmt) == 1

    column_info = Oracle.column_info(stmt, 1)
    @test Oracle.column_name(column_info) == "ID"

    Oracle.close!(stmt)
end

@testset "fetch" begin
    stmt = Oracle.Stmt(conn, "SELECT ID FROM TB_TEST")
    Oracle.execute!(stmt)

    result = Oracle.fetch!(stmt)
    @test result.found

    value = Oracle.query_oracle_value(stmt, 1)[]
    @test value == 1.0
    @test isa(value, Float64)

    result = Oracle.fetch!(stmt)
    @test result.found

    value = Oracle.query_oracle_value(stmt, 1)[]
    @test ismissing(value)
    @test isa(value, Missing)

    Oracle.close!(stmt)
end

@testset "Drop" begin
    Oracle.execute!(conn, "DROP TABLE TB_TEST")
end

@testset "ExternOracleValue" begin
    Oracle.execute!(conn, "CREATE TABLE TB_TEST_DATATYPES ( ID NUMBER(38,0) NULL, name VARCHAR2(255) NULL,  amount NUMBER(15,2) NULL)")

    Oracle.execute!(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 1, 'hello world', 123.45 )")
    Oracle.execute!(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 2, '📚📚📚📚⏳😀⌛😭', 10 )")
    Oracle.execute!(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 3, 'áÁàÀãÃâÂéÉíÍóÓõÕúÚçÇ', .1 )")
    Oracle.commit!(conn)

    stmt = Oracle.Stmt(conn, "SELECT ID, name, amount FROM TB_TEST_DATATYPES")
    Oracle.execute!(stmt)
    @test Oracle.num_columns(stmt) == 3

    result = Oracle.fetch!(stmt)
    @test result.found

    iter = 1
    id_values = [1, 2, 3]
    name_values = [ "hello world", "📚📚📚📚⏳😀⌛😭", "áÁàÀãÃâÂéÉíÍóÓõÕúÚçÇ" ]
    amount_values = [123.45, 10, .1]

    println("")
    println("Printing out UTF-8 strings")

    while result.found

        value_id = Oracle.query_oracle_value(stmt, 1)[]
        value_name = Oracle.query_oracle_value(stmt, 2)[]
        value_amount = Oracle.query_oracle_value(stmt, 3)[]

        println(value_name)

        @test id_values[iter] == value_id
        @test name_values[iter] == value_name
        @test amount_values[iter] == value_amount

        result = Oracle.fetch!(stmt)
        iter += 1
    end

    println("")

    Oracle.close!(stmt)
    Oracle.execute!(conn, "DROP TABLE TB_TEST_DATATYPES")
end

@testset "OraData" begin
    ctx = Oracle.Context()

    data_handle = Ref{Oracle.OraData}()

    let
        str = "hey you"
        Oracle.dpiData_setBytes(data_handle, str)
    end

    let
        local ptr_bytes::Ptr{Oracle.OraBytes} = Oracle.dpiData_getBytes(data_handle)
        ora_string = unsafe_load(ptr_bytes) # get a OraBytes
        @test unsafe_string(ora_string.ptr, ora_string.length) == "hey you"
    end
end

@testset "JuliaOracleValue" begin

    @testset "Int" begin
        julia_oracle_value = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_NATIVE_INT, Oracle.ORA_NATIVE_TYPE_INT64, Int64)
        julia_oracle_value[] = 10
        @test julia_oracle_value[] == 10
        @test julia_oracle_value[0] == julia_oracle_value[]
    end

    @testset "UInt64" begin
        julia_oracle_value = Oracle.JuliaOracleValue(UInt64(10000))
        @test julia_oracle_value[] == UInt64(10000)
    end

    @testset "Missing" begin
        julia_oracle_value = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_NATIVE_INT, Oracle.ORA_NATIVE_TYPE_INT64, Union{Missing, Int64})
        julia_oracle_value[] = missing
        @test ismissing(julia_oracle_value[])
    end

    @testset "Float64" begin
        julia_oracle_value = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_NUMBER, Oracle.ORA_NATIVE_TYPE_DOUBLE, Float64)
        julia_oracle_value[] = 10.5
        @test julia_oracle_value[] == 10.5
    end

    @testset "VARCHAR" begin
        julia_oracle_value = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_VARCHAR, Oracle.ORA_NATIVE_TYPE_BYTES, String)
        julia_oracle_value[] = "hey you"
        @test julia_oracle_value[] == "hey you"
    end

    @testset "RAW" begin
        julia_oracle_value = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_RAW, Oracle.ORA_NATIVE_TYPE_BYTES, Vector{UInt8})
        test_data = rand(UInt8, 200)
        julia_oracle_value[] = copy(test_data)
        @test julia_oracle_value[] == test_data
    end

    @testset "Stmt bind" begin
        stmt = Oracle.Stmt(conn, "SELECT :A, :B FROM DUAL")
        val_a = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_NUMBER, Oracle.ORA_NATIVE_TYPE_DOUBLE, Float64)
        val_a[] = 10.5
        val_b = Oracle.JuliaOracleValue(Oracle.ORA_ORACLE_TYPE_VARCHAR, Oracle.ORA_NATIVE_TYPE_BYTES, String)
        val_b[] = "hey"
        Oracle.bind_value!(stmt, val_a, :A)
        Oracle.bind_value!(stmt, val_b, 2)
        Oracle.close!(stmt)
    end

    @testset "type inference" begin

        @test Oracle.infer_oracle_type_tuple(Bool) == Oracle.infer_oracle_type_tuple(true)

        v_int = Oracle.JuliaOracleValue(10)
        @test v_int[] == 10

        v_str = Oracle.JuliaOracleValue("str")
        @test v_str[] == "str"

        v_double = Oracle.JuliaOracleValue(10.5)
        @test v_double[] == 10.5

        v_raw = Oracle.JuliaOracleValue(UInt8[0x10, 0x11, 0x12, 0x13])
        @test v_raw[] == UInt8[0x10, 0x11, 0x12, 0x13]
    end
end

@testset "Timestamp" begin
    Oracle.execute!(conn, "CREATE TABLE TB_DATE ( DT DATE NULL )")
    Oracle.execute!(conn, "INSERT INTO TB_DATE (DT) VALUES ( TO_DATE('2018-12-31', 'yyyy-mm-dd') )")
    Oracle.execute!(conn, "INSERT INTO TB_DATE (DT) VALUES ( TO_DATE('2018-12-31 11:55:35 P.M.', 'yyyy-mm-dd HH:MI:SS A.M.') )")
    Oracle.commit!(conn)

    let
        dates = [ Date(2018, 12, 31), DateTime(2018, 12, 31, 23, 55, 35) ]

        row_number = 1

        Oracle.query(conn, "SELECT DT FROM TB_DATE") do cursor
            for row in cursor
                @test row["DT"] == dates[row_number]
                @test isa(row["DT"], DateTime) # Oracle DATE columns stores DateTime up to seconds.

                row_number += 1
            end
        end
    end

    Oracle.execute!(conn, "DROP TABLE TB_DATE")
end

@testset "RAW" begin
    Oracle.execute!(conn, "CREATE TABLE TB_QUERY_RAW ( RAW_COLUMN RAW(2000) )")
    Oracle.execute!(conn, "INSERT INTO TB_QUERY_RAW ( RAW_COLUMN ) VALUES ( utl_raw.cast_to_raw('raw column value') )")

    Oracle.query(conn, "SELECT RAW_COLUMN FROM TB_QUERY_RAW") do cursor
        for row in cursor
            byte_array = row["RAW_COLUMN"]
            @test isa(byte_array, Vector{UInt8})
            @test String(byte_array) == "raw column value"
        end
    end

    Oracle.execute!(conn, "DROP TABLE TB_QUERY_RAW")
end

@testset "Lob" begin
    @testset "Temp Lob" begin
        for lob_type_num in ( Oracle.ORA_ORACLE_TYPE_BLOB, Oracle.ORA_ORACLE_TYPE_CLOB, Oracle.ORA_ORACLE_TYPE_NCLOB )
            lob = Oracle.Lob(conn, lob_type_num)
            @test Oracle.is_character_data(lob) == Bool(Oracle.dpiLob_isCharacterData(lob.handle))
            @test Oracle.oracle_type(lob) == Oracle.dpiLob_getOracleTypeNum(lob.handle)
            @test Oracle.chunk_size(lob) != 0
            Oracle.close!(lob)
        end
    end

    @testset "Read BLOB" begin

        lyric = "hey you. 🎵 🎶 Out there in the cold. getting lonely, getting old. Can you feel me? 📼📼📼📼"

        Oracle.execute!(conn, "CREATE TABLE TB_BLOB ( B BLOB )")
        Oracle.execute!(conn, "INSERT INTO TB_BLOB ( B ) VALUES ( utl_raw.cast_to_raw('$lyric'))")

        function check_blob_data(test_data::String, lob, buffer_size)

            @test Oracle.oracle_type(lob) == Oracle.ORA_ORACLE_TYPE_BLOB

            out = IOBuffer()
            open(lob, "r", buffer_size=buffer_size) do io
                while !eof(io)
                    write(out, read(io, Char))
                end

                @test eof(io)
                @test_throws EOFError read(io, Char)
            end

            @test test_data == String(take!(out))
            Oracle.close!(lob)
        end

        function query_and_check_blob_data(test_data::String, buffer_size)
            stmt = Oracle.Stmt(conn, "SELECT B FROM TB_BLOB")

            try
                Oracle.execute!(stmt)
                result = Oracle.fetch!(stmt)
                @test result.found
                blob = Oracle.query_oracle_value(stmt, 1)[]
                check_blob_data(test_data, blob, buffer_size)
            finally
                Oracle.close!(stmt)
            end
        end

        buff_sizes_to_check = [ 30, sizeof(lyric)-1, sizeof(lyric), sizeof(lyric)+1, nothing ]

        for buff_size in buff_sizes_to_check
            query_and_check_blob_data(lyric, buff_size)
        end

        Oracle.execute!(conn, "DROP TABLE TB_BLOB")
    end
#=
    @testset "Write BLOB" begin
        #Oracle.execute!(conn, "DROP TABLE TB_WRITE_BLOB")
        Oracle.execute!(conn, "CREATE TABLE TB_WRITE_BLOB ( B BLOB )")

        blob = Oracle.Lob(conn, Oracle.ORA_ORACLE_TYPE_BLOB)
        data = rand(UInt8, 5000)
        write(blob, data)

        stmt = Oracle.Stmt(conn, "INSERT INTO TB_WRITE_BLOB ( B ) VALUES ( :1 )")
        stmt[1] = blob # ERROR: DPI-1014: conversion between Oracle type 0 and native type 3008 is not implemented
        Oracle.execute!(stmt)
        Oracle.close!(stmt)

        Oracle.execute!(conn, "DROP TABLE TB_WRITE_BLOB")
    end
=#
    @testset "Read CLOB" begin
        #utfchar_5bytes = "a🎵" # https://github.com/oracle/odpi/issues/94
        test_string = "abcdefghij"^250
        @assert sizeof(test_string) == 2500

        Oracle.execute!(conn, "CREATE TABLE TB_CLOB ( B CLOB )")
        Oracle.execute!(conn, "INSERT INTO TB_CLOB ( B ) VALUES ( '$(test_string)' )")

        let
            stmt = Oracle.Stmt(conn, "SELECT B FROM TB_CLOB")
            local clob::Oracle.Lob

            try
                Oracle.execute!(stmt)
                result = Oracle.fetch!(stmt)
                @test result.found
                clob = Oracle.query_oracle_value(stmt, 1)[]

                open(clob, "r") do io
                    i = 1
                    while !eof(io)
                        @test read(io, Char) == test_string[i]
                        i += 1
                    end

                    seek(io, 2)
                    @test read(io, Char) == test_string[3]
                    @test position(io) == 3

                    seekstart(io)
                    @test read(io, Char) == test_string[1]

                end
            finally
                Oracle.close!(clob)
                Oracle.close!(stmt)
            end
        end

        let
            stmt = Oracle.Stmt(conn, "SELECT B FROM TB_CLOB")
            local clob::Oracle.Lob

            try
                Oracle.execute!(stmt)
                result = Oracle.fetch!(stmt)
                @test result.found
                clob = Oracle.query_oracle_value(stmt, 1)[]

                open(clob, "r") do io
                    @test read(io, String) == test_string
                end
            finally
                Oracle.close!(clob)
                Oracle.close!(stmt)
            end
        end

        let
            stmt = Oracle.Stmt(conn, "SELECT B FROM TB_CLOB")
            local clob::Oracle.Lob

            try
                Oracle.execute!(stmt)
                result = Oracle.fetch!(stmt)
                @test result.found
                clob = Oracle.query_oracle_value(stmt, 1)[]

                open(clob, "r", buffer_size=2000) do io

                    seek(io, length(test_string)-1)
                    @test read(io, Char) == test_string[end]

                    seekstart(io)
                    i = 1
                    while !eof(io)
                        @test read(io, Char) == test_string[i]
                        i += 1
                    end
                end
            finally
                Oracle.close!(clob)
                Oracle.close!(stmt)
            end
        end

        let
            stmt = Oracle.Stmt(conn, "SELECT B FROM TB_CLOB")
            local clob::Oracle.Lob

            try
                Oracle.execute!(stmt)
                result = Oracle.fetch!(stmt)
                @test result.found
                clob = Oracle.query_oracle_value(stmt, 1)[]

                open(clob, "r", buffer_size=2000) do io
                    @test read(io, String) == test_string
                end
            finally
                Oracle.close!(clob)
                Oracle.close!(stmt)
            end
        end

        Oracle.execute!(conn, "DROP TABLE TB_CLOB")
    end
end

@testset "Fetch Many" begin
    Oracle.execute!(conn, "CREATE TABLE TB_TEST_FETCH_MANY ( ID NUMBER(4,0) NULL, VAL NUMBER(4,0) NULL )")

    let
        col1 = collect(1:10)
        col2 = 10*col1
        Oracle.execute!(conn, "INSERT INTO TB_TEST_FETCH_MANY ( ID, VAL ) VALUES ( :1, :2 )", [col1, col2])
    end

    stmt = Oracle.Stmt(conn, "SELECT ID, VAL FROM TB_TEST_FETCH_MANY")
    Oracle.execute!(stmt)
    @test Oracle.num_columns(stmt) == 2

    fetch_rows_result = Oracle.fetch_rows!(stmt, 3)

    @test fetch_rows_result.buffer_row_index == 0
    @test fetch_rows_result.num_rows_fetched == 3
    @test fetch_rows_result.more_rows == 1

    Oracle.close!(stmt)
    Oracle.execute!(conn, "DROP TABLE TB_TEST_FETCH_MANY")
end

@testset "Cursor" begin
    Oracle.execute!(conn, "CREATE TABLE TB_TEST_CURSOR ( ID NUMBER(4,0) NULL, VAL NUMBER(15,0) NULL, VAL_FLT NUMBER(4,2), STR VARCHAR2(255) )")

    num_iterations = 10

    let
        col1 = collect(1:num_iterations)
        col2 = 10*col1
        col3 = fill(10.01, num_iterations)
        col4 = fill("📚📚📚📚⏳😀⌛😭", num_iterations)
        columns = [ col1, col2, col3, col4 ]
        Oracle.execute!(conn, "INSERT INTO TB_TEST_CURSOR ( ID, VAL, VAL_FLT, STR ) VALUES ( :1, :2, :3, :4 )", columns)
    end

    @testset "all rows" begin
        row_number = 0

        Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR", fetch_array_size=3) do cursor
            for row in cursor
                row_number += 1
                @test row["ID"] == row_number
                @test isa(row["ID"], Int)
                @test row["ID"] == row[1]

                @test row["VAL"] == row_number * 10
                @test isa(row["VAL"], Int)
                @test row["VAL"] == row[2]

                @test row["VAL_FLT"] == 10.01
                @test isa(row["VAL_FLT"], Float64)
                @test row["VAL_FLT"] == row[3]

                @test row["STR"] == "📚📚📚📚⏳😀⌛😭"
                @test isa(row["STR"], String)
                @test row["STR"] == row[4]
            end
        end
        @test row_number == num_iterations
    end

    @testset "collect" begin
        local resultset

        Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR") do cursor
            resultset = collect(cursor)
        end

        @test length(resultset) == num_iterations
        row_number = 0
        for row in resultset
            row_number += 1
            @test row["ID"] == row_number
            @test isa(row["ID"], Int)
            @test row["ID"] == row[1]

            @test row["VAL"] == row_number * 10
            @test isa(row["VAL"], Int)
            @test row["VAL"] == row[2]

            @test row["VAL_FLT"] == 10.01
            @test isa(row["VAL_FLT"], Float64)
            @test row["VAL_FLT"] == row[3]

            @test row["STR"] == "📚📚📚📚⏳😀⌛😭"
            @test isa(row["STR"], String)
            @test row["STR"] == row[4]
        end
    end

    @testset "2nd row" begin
        row_number = 0
        Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR WHERE ID = 2", fetch_array_size=3) do cursor
            for row in cursor
                row_number += 1
                @test row["ID"] == 2
                @test row["VAL"] == 20
            end
        end
        @test row_number == 1
    end

    @testset "1st and 2nd rows" begin
        row_number = 0

        Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR WHERE ID = 1 OR ID = 2", fetch_array_size=3) do cursor
            for row in cursor
                row_number += 1
                @test row["ID"] == row_number
                @test row["VAL"] == row_number * 10
            end
        end

        @test row_number == 2
    end

    @testset "1st, 2nd, 3rd rows" begin
        row_number = 0

        Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR WHERE ID = 1 OR ID = 2 OR ID = 3", fetch_array_size=3) do cursor
            for row in cursor
                row_number += 1
                @test row["ID"] == row_number
                @test row["VAL"] == row_number * 10
            end
        end

        @test row_number == 3
    end

    @testset "1st, 2nd, 3rd, 4th rows" begin
        row_number = 0

        Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR WHERE ID = 1 OR ID = 2 OR ID = 3 OR ID = 4", fetch_array_size=3) do cursor
            for row in cursor
                row_number += 1
                @test row["ID"] == row_number
                @test row["VAL"] == row_number * 10
            end
        end

        @test row_number == 4
    end

    Oracle.execute!(conn, "DROP TABLE TB_TEST_CURSOR")
end

@testset "execute script" begin
    Oracle.execute!(conn, "CREATE TABLE TB_ACCOUNTS ( ID NUMBER(4,0), AMOUNT NUMBER(12,2) )")

    let
        stmt = Oracle.Stmt(conn, "INSERT INTO TB_ACCOUNTS ( ID, AMOUNT ) VALUES ( :ID, :AMT )")
        stmt[:ID] = 1
        stmt[:AMT] = 20.50
        Oracle.execute!(stmt)

        stmt[:ID] = 2
        stmt[:AMT] = 100.00
        Oracle.execute!(stmt)

        stmt[:ID] = 3
        stmt[:AMT] = 150.00
        Oracle.execute!(stmt)

        Oracle.commit!(conn)
    end

    Oracle.execute_script!(conn, joinpath(@__DIR__, "update_account_2.sql"))

    Oracle.query(conn, "SELECT AMOUNT FROM TB_ACCOUNTS WHERE ID = 2") do cursor
        row_count = 0
        for row in cursor
            row_count += 1
            @test row["AMOUNT"] == 10.0
        end

        @test row_count == 1
    end

    Oracle.execute!(conn, "DROP TABLE TB_ACCOUNTS")
end

@testset "Bind" begin

    @testset "bind int, flt, str, date by name" begin
        Oracle.execute!(conn, "CREATE TABLE TB_BIND_BY_NAME ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)")

        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_BY_NAME ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )")
        @test stmt.bind_count == 4

        @test_throws AssertionError stmt[:invalid_bind_name] = 10

        for i in 1:10
            stmt[:id] = 1 + i
            stmt[:flt] = 10.23 + i
            stmt[:str] = "🍕 $i"
            stmt[:dt] = Date(2018,12,31) + Dates.Day(i)
            Oracle.execute!(stmt)
        end
        Oracle.commit!(conn)

        let
            row_number = 1

            Oracle.query(conn, "SELECT * FROM TB_BIND_BY_NAME") do cursor
                for row in cursor
                    @test row["ID"] == 1 + row_number
                    @test row["FLT"] == 10.23 + row_number
                    @test row["STR"] == "🍕 $row_number"
                    @test row["DT"] == Date(2018,12,31) + Dates.Day(row_number)

                    row_number += 1
                end
            end

            @test row_number == 11
        end

        @testset "reuse stmt for queries" begin
            query_stmt = Oracle.Stmt(conn, "SELECT FLT FROM TB_BIND_BY_NAME WHERE ID = :id")

            query_stmt[:ID] = 2
            Oracle.query(query_stmt) do cursor
                for row in cursor
                    @test row["FLT"] == 10.23 + 1
                end
            end

            query_stmt[:ID] = 3
            Oracle.query(query_stmt) do cursor
                for row in cursor
                    @test row["FLT"] == 10.23 + 2
                end
            end

            Oracle.close!(query_stmt)
        end

        Oracle.execute!(conn, "DELETE FROM TB_BIND_BY_NAME")

        stmt[:id, Int] = missing
        stmt[:flt, Float64] = missing
        stmt[:str, String] = missing
        stmt[:dt, Date] = missing

        @test_throws ErrorException stmt[:dt] = missing
        @test_throws MethodError stmt[:dt, Int] = 1

        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let
            row_number = 0

            Oracle.query(conn, "SELECT * FROM TB_BIND_BY_NAME") do cursor
                for row in cursor
                    @test ismissing(row["ID"])
                    @test ismissing(row["FLT"])
                    @test ismissing(row["STR"])
                    @test ismissing(row["DT"])
                    row_number += 1
                end
            end

            @test row_number == 1
        end

        Oracle.close!(stmt)
        Oracle.execute!(conn, "DROP TABLE TB_BIND_BY_NAME")
    end

    @testset "bind int, flt, str, date by position" begin
        Oracle.execute!(conn, "CREATE TABLE TB_BIND_BY_POSITION ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)")

        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_BY_POSITION ( ID, FLT, STR, DT ) VALUES ( :a, :b, :c, :d )")
        @test stmt.bind_count == 4

        @test_throws AssertionError stmt[0] = 10
        @test_throws AssertionError stmt[5] = 10

        for i in 1:10
            stmt[1] = 1 + i
            stmt[2] = 10.23 + i
            stmt[3] = "🍕 $i"
            stmt[4] = Date(2018,12,31) + Dates.Day(i)
            Oracle.execute!(stmt)
        end
        Oracle.commit!(conn)

        let
            row_number = 1

            Oracle.query(conn, "SELECT * FROM TB_BIND_BY_POSITION") do cursor
                for row in cursor
                    @test row["ID"] == 1 + row_number
                    @test row["FLT"] == 10.23 + row_number
                    @test row["STR"] == "🍕 $row_number"
                    @test row["DT"] == Date(2018,12,31) + Dates.Day(row_number)

                    row_number += 1
                end
            end

            @test row_number == 11
        end

        Oracle.execute!(conn, "DELETE FROM TB_BIND_BY_POSITION")

        stmt[1, Int] = missing
        stmt[2, Float64] = missing
        stmt[3, String] = missing
        stmt[4, Date] = missing

        @test_throws ErrorException stmt[:dt] = missing
        @test_throws MethodError stmt[:dt, Int] = 1

        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let
            row_number = 0

            Oracle.query(conn, "SELECT * FROM TB_BIND_BY_POSITION") do cursor
                for row in cursor
                    @test ismissing(row["ID"])
                    @test ismissing(row["FLT"])
                    @test ismissing(row["STR"])
                    @test ismissing(row["DT"])
                    row_number += 1
                end
            end

            @test row_number == 1
        end

        Oracle.close!(stmt)
        Oracle.execute!(conn, "DROP TABLE TB_BIND_BY_POSITION")
    end

    @testset "Bind DateTime and Timestamp" begin
        Oracle.execute!(conn, "CREATE TABLE TB_BIND_TIMESTAMP ( TS TIMESTAMP(9) NULL )")

        dt_now = Dates.now()
        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_TIMESTAMP ( TS ) VALUES ( :ts )")
        stmt[:ts] = dt_now
        Oracle.execute!(stmt)
        ts = Oracle.Timestamps.Timestamp(2018, 12, 31, 23, 58, 59, 999_200_300)
        stmt[:ts] = ts
        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let row_number = 0

            Oracle.query(conn, "SELECT TS FROM TB_BIND_TIMESTAMP") do cursor
                for row in cursor
                    row_number += 1

                    if row_number == 1
                        @test row["TS"] == dt_now
                    else
                        @test row["TS"] == ts
                    end

                    @test isa(row["TS"], Oracle.Timestamps.Timestamp)
                end
            end

            @test row_number == 2
        end

        Oracle.close!(stmt)
        Oracle.execute!(conn, "DROP TABLE TB_BIND_TIMESTAMP")
    end

    @testset "Bind DateTime and Timestamp" begin
        Oracle.execute!(conn, "CREATE TABLE TB_BIND_TIMESTAMP_TZ ( TS_TZ TIMESTAMP(9) WITH TIME ZONE, TS_LTZ TIMESTAMP(9) WITH LOCAL TIME ZONE )")

        ts_tz = Oracle.Timestamps.TimestampTZ(false, 2018, 12, 31, 23, 58, 59, 999_200_300, -3, 0)
        ts_ltz = Oracle.Timestamps.TimestampTZ(true, 2018, 12, 31, 23, 58, 59, 999_200_400, -3, 0)

        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_TIMESTAMP_TZ ( TS_TZ, TS_LTZ ) VALUES ( :ts_tz, :ts_ltz )")
        stmt[:ts_tz] = ts_tz
        stmt[:ts_ltz] = ts_ltz
        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let row_number = 0

            Oracle.query(conn, "SELECT TS_TZ, TS_LTZ FROM TB_BIND_TIMESTAMP_TZ") do cursor
                for row in cursor
                    row_number += 1


                    println("TS_TZ = ", row["TS_TZ"])
                    println("TS_LTZ = ", row["TS_LTZ"])
#=
                    @test row["TS_TZ"] == ts_tz
                    @test second(row["TS_LTZ"]) == second(ts_ltz)
                    @test millisecond(row["TS_LTZ"]) == millisecond(ts_ltz)
                    @test microsecond(row["TS_LTZ"]) == microsecond(ts_ltz)
                    @test nanosecond(row["TS_LTZ"]) == nanosecond(ts_ltz)
=#
                end
            end

            @test row_number == 1
        end

        Oracle.close!(stmt)
        Oracle.execute!(conn, "DROP TABLE TB_BIND_TIMESTAMP_TZ")
    end

#=
    @testset "Bind RAW" begin
        #Oracle.execute!(conn, "DROP TABLE TB_RAW")
        #Oracle.execute!(conn, "CREATE TABLE TB_RAW ( bytes RAW(2000), bytes_long LONG RAW )")
        Oracle.execute!(conn, "CREATE TABLE TB_RAW ( RAW_BYTES RAW(2000) )")

        bytes = UInt8[0x01, 0xff, 0x22] #rand(UInt8, 2000)
        #bytes_long = UInt8[0x01, 0xff, 0x22] #rand(UInt8, 10000)

        let
            stmt = Oracle.Stmt(conn, "INSERT INTO TB_RAW ( RAW_BYTES ) VALUES ( :a )")
            stmt[1] = bytes
            #stmt[2] = bytes_long
            Oracle.execute!(stmt)
            Oracle.commit!(conn)
            Oracle.close!(stmt)
        end

        Oracle.query(conn, "SELECT RAW_BYTES FROM TB_RAW") do cursor
            for row in cursor
                @test row["RAW_BYTES"] == bytes
                #@test row["BYTES_LONG"] == bytes_long
            end
        end

        Oracle.execute!(conn, "DROP TABLE TB_RAW")
    end
=#
end

@testset "Variables" begin

    @testset "get/set values to Variables" begin
        ora_var = Oracle.Variable(conn, Float64, Oracle.ORA_ORACLE_TYPE_NATIVE_DOUBLE, Oracle.ORA_NATIVE_TYPE_DOUBLE)

        ora_var[0] = 0.0
        @test ora_var[0] == 0.0

        let
            for i in 0:(ora_var.buffer_capacity-1)
                ora_var[i] = Float64(i)
            end

            for i in 0:(ora_var.buffer_capacity-1)
                @test ora_var[i] == Float64(i)
            end
        end

        @test_throws AssertionError ora_var[-1] = 1.0
        @test_throws AssertionError ora_var[ora_var.buffer_capacity] = 1.0

        @test_throws AssertionError ora_var[-1] == 1.0
        @test_throws AssertionError ora_var[ora_var.buffer_capacity] == 1.0
    end

    Oracle.execute!(conn, "CREATE TABLE TB_VARIABLES ( FLT NUMBER(15,4) NULL )")

    @testset "low-level define API" begin
        ora_var = Oracle.Variable(conn, Union{Missing, Float64})

        Oracle.execute!(conn, "INSERT INTO TB_VARIABLES ( FLT ) VALUES ( :1 )", [ [123.45, 456.78, missing] ])
        stmt = Oracle.Stmt(conn, "SELECT FLT FROM TB_VARIABLES")
        Oracle.execute!(stmt)

        Oracle.define(stmt, 1, ora_var)

        fetch_result = Oracle.fetch_rows!(stmt)
        @test fetch_result.num_rows_fetched == 3

        v = Oracle.ExternOracleValue(ora_var, ora_var.oracle_type, ora_var.native_type, ora_var.buffer_handle)
        @test v[fetch_result.buffer_row_index + 0] == 123.45
        @test v[fetch_result.buffer_row_index + 1] == 456.78
        @test ismissing(v[fetch_result.buffer_row_index + 2])

        Oracle.close!(stmt)
        Oracle.rollback!(conn)
    end

    @testset "bind to stmt" begin
        ora_var = Oracle.Variable(conn, Float64)
        stmt = Oracle.Stmt(conn, "INSERT INTO TB_VARIABLES ( FLT ) VALUES ( :flt )")
        stmt[:flt] = ora_var
        Oracle.close!(stmt)
    end

    @testset "low-level executeMany" begin
        how_many = 10

        let
            ora_var = Oracle.Variable(conn, Float64)

            for i in 0:(how_many-1)
                ora_var[i] = Float64(i)
            end

            stmt = Oracle.Stmt(conn, "INSERT INTO TB_VARIABLES ( FLT ) VALUES ( :flt )")
            stmt[:flt] = ora_var
            result = Oracle.dpiStmt_executeMany(stmt.handle, Oracle.ORA_MODE_EXEC_DEFAULT, UInt32(how_many))
            Oracle.error_check(Oracle.context(stmt), result)

            Oracle.close!(stmt)
            Oracle.commit!(conn)
        end

        Oracle.query(conn, "SELECT FLT FROM TB_VARIABLES") do cursor
            row_number = 0.0
            for row in cursor
                @test row["FLT"] == row_number
                row_number += 1
            end
            @test row_number == how_many
        end
    end

    Oracle.execute!(conn, "DROP TABLE TB_VARIABLES")

    function check_data(cursor::Oracle.Cursor, columns)
        row_count = length(columns[1])
        column_count = length(columns)

        row_number = 1
        for row in cursor
            for c in 1:column_count
                val = columns[c][row_number]
                if ismissing(val)
                    @test ismissing(row[c])
                else
                    @test val == row[c]
                end
            end
            row_number += 1
        end
    end

    @testset "high-level executeMany" begin
        Oracle.execute!(conn, "CREATE TABLE TB_EXECUTE_MANY ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR2(4000) )")

        columns = [ [1, 2, 3, 4, 5], [10.5, 20.5, 30.5, 40.5, missing], ["1", "2nd string is awesomely the biggest one", "3", "4th string is bigger", missing] ]
        Oracle.execute!(conn, "INSERT INTO TB_EXECUTE_MANY ( ID, FLT, STR ) VALUES ( :1, :2, :3 )", columns)

        Oracle.query(conn, "SELECT ID, FLT, STR FROM TB_EXECUTE_MANY") do cursor
            check_data(cursor, columns)
        end

        Oracle.execute!(conn, "DROP TABLE TB_EXECUTE_MANY")
    end

    @testset "BLOB Variable" begin
        Oracle.execute!(conn, "CREATE TABLE TB_BLOB_VARIABLE ( B BLOB )")

        test_data = rand(UInt8, 5000)

        let
            blob = Oracle.Lob(conn, Oracle.ORA_ORACLE_TYPE_BLOB)
            write(blob, test_data)

            ora_var = Oracle.Variable(conn, blob)

            stmt = Oracle.Stmt(conn, "INSERT INTO TB_BLOB_VARIABLE ( B ) VALUES ( :1 )")
            stmt[1] = ora_var
            Oracle.execute!(stmt)
            Oracle.close!(stmt)
        end

        let
            Oracle.query(conn, "SELECT B FROM TB_BLOB_VARIABLE") do cursor
                for row in cursor
                    blob = row["B"]
                    @test isa(blob, Oracle.Lob)
                    read_data = read(blob)
                    @test read_data == test_data
                    Oracle.close!(blob)
                end
            end
        end

        Oracle.execute!(conn, "DROP TABLE TB_BLOB_VARIABLE")
    end

    @testset "CLOB Variable" begin
        Oracle.execute!(conn, "CREATE TABLE TB_CLOB_VARIABLE ( C CLOB )")

        test_data = "Lorem ipsum dolor sit amet"^1000

        let
            clob = Oracle.Lob(conn, Oracle.ORA_ORACLE_TYPE_CLOB)
            write(clob, test_data)

            ora_var = Oracle.Variable(conn, clob)

            stmt = Oracle.Stmt(conn, "INSERT INTO TB_CLOB_VARIABLE ( C ) VALUES ( :1 )")
            stmt[1] = ora_var
            Oracle.execute!(stmt)
            Oracle.close!(stmt)
        end

        let
            Oracle.query(conn, "SELECT C FROM TB_CLOB_VARIABLE") do cursor
                for row in cursor
                    clob = row["C"]
                    @test isa(clob, Oracle.Lob)
                    read_data = read(clob)
                    @test read_data == test_data
                    Oracle.close!(clob)
                end
            end
        end

        Oracle.execute!(conn, "DROP TABLE TB_CLOB_VARIABLE")
    end
end

if auth_mode != Oracle.ORA_MODE_AUTH_SYSDBA
    @testset "Pool" begin

        @testset "Create a Pool" begin
            ctx = Oracle.Context()

            let
                pool = Oracle.Pool(ctx, username, password, connect_string)
                Oracle.close!(pool)
            end

            let
                pool = Oracle.Pool(ctx, username, password, connect_string, min_sessions=2, max_sessions=4, session_increment=1)
                @test Oracle.pool_get_mode(pool) == Oracle.ORA_MODE_POOL_GET_NOWAIT
                Oracle.close!(pool)
            end

            let
                pool = Oracle.Pool(ctx, username, password, connect_string, get_mode=Oracle.ORA_MODE_POOL_GET_WAIT)
                @test Oracle.pool_get_mode(pool) == Oracle.ORA_MODE_POOL_GET_WAIT
                Oracle.close!(pool)
            end
        end

        @testset "Acquire connection from pool" begin
            pool = Oracle.Pool(username, password, connect_string, max_sessions=2, session_increment=1)

            conn_1 = Oracle.Connection(pool)
            conn_2 = Oracle.Connection(pool)

            Oracle.close!(conn_1)

            conn_3 = Oracle.Connection(pool)

            Oracle.close!(conn_2)
            Oracle.close!(conn_3)

            Oracle.close!(pool)
        end

        @testset "Supported encodings" begin
            for enc in Oracle.SUPPORTED_CONNECTION_ENCODINGS
                pool = Oracle.Pool(username, password, connect_string, encoding=enc, nencoding=enc)
                conn_enc = Oracle.Connection(pool, auth_mode=auth_mode)
                Oracle.close!(conn_enc)
                Oracle.close!(pool)
            end
        end
    end
end

#=
@testset "shutdown/startup" begin
    # The connection needs to have been established at least with authorization mode set to ORA_MODE_AUTH_SYSDBA or ORA_MODE_AUTH_SYSOPER
    Oracle.shutdown_database(conn)
    Oracle.startup_database(conn)
end
=#

Oracle.close!(conn)
