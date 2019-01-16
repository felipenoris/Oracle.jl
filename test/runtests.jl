
import Oracle

if VERSION < v"0.7-"
    using Base.Test
    using Missings
else
    using Test
    using Dates
end

@assert isfile(joinpath(@__DIR__, "credentials.jl")) """
Before running tests, create a file `test/credentials.jl` with the content:

username = "your-username"
password = "your-password"
connect_string = "your-connect-string"
"""
include("credentials.jl")

function simple_query(conn::Oracle.Connection, sql::String)
    stmt = Oracle.Stmt(conn, sql)
    Oracle.execute!(stmt)
    Oracle.close!(stmt)
end

conn = Oracle.Connection(username, password, connect_string, auth_mode=Oracle.ORA_MODE_AUTH_SYSDBA) # in case the database user is sysdba
#conn = Oracle.Connection(username, password, connect_string) # in case the database user is a regular user

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
    for row in Oracle.query(conn, "select value from nls_database_parameters where parameter='NLS_CHARACTERSET'")
        println("Database NLS_CHARACTERSET = ", row["VALUE"])
    end
end

# Connection Encoding Info
let
    println("Connection encoding info: ", conn.encoding_info)
end

println("")

@testset "ping" begin
    Oracle.ping(conn)
end

@testset "query/commit/rollback" begin
    simple_query(conn, "CREATE TABLE TB_TEST ( ID INT NULL )")
    simple_query(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 1 )")
    simple_query(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( null )")
    Oracle.commit!(conn)

    simple_query(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 3 )")
    Oracle.rollback!(conn)
end

@testset "Stmt" begin
    stmt = Oracle.Stmt(conn, "SELECT * FROM TB_TEST")

    @test stmt.info.is_query
    @test !stmt.info.is_DDL
    @test !stmt.info.is_DML
    @test stmt.info.statement_type == Oracle.ORA_STMT_TYPE_SELECT

    query_result = Oracle.execute!(stmt)
    @test isa(query_result, Oracle.QueryExecutionResult)
    @test query_result.num_columns == 1

    query_info = Oracle.OraQueryInfo(stmt, 1)
    @test Oracle.column_name(query_info) == "ID"
end

@testset "fetch" begin
    stmt = Oracle.Stmt(conn, "SELECT ID FROM TB_TEST")
    Oracle.execute!(stmt)

    result = Oracle.fetch!(stmt)
    @test result.found

    value = Oracle.query_value(stmt, 1)
    @test !Oracle.is_null(value)
    @test value[] == 1.0
    @test isa(value[], Float64)

    result = Oracle.fetch!(stmt)
    @test result.found

    value = Oracle.query_value(stmt, 1)
    @test Oracle.is_null(value)
    @test ismissing(value[])
    @test isa(value[], Missing)
end

@testset "Drop" begin
    simple_query(conn, "DROP TABLE TB_TEST")
end

@testset "parse data" begin
    simple_query(conn, "CREATE TABLE TB_TEST_DATATYPES ( ID NUMBER(38,0) NULL, name VARCHAR2(255) NULL,  amount NUMBER(15,2) NULL)")

    simple_query(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 1, 'hello world', 123.45 )")
    simple_query(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 2, '📚📚📚📚⏳😀⌛😭', 10 )")
    simple_query(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 3, 'áÁàÀãÃâÂéÉíÍóÓõÕúÚçÇ', .1 )")
    Oracle.commit!(conn)

    stmt = Oracle.Stmt(conn, "SELECT ID, name, amount FROM TB_TEST_DATATYPES")
    query_result = Oracle.execute!(stmt)
    @test query_result.num_columns == 3

    result = Oracle.fetch!(stmt)
    @test result.found

    iter = 1
    id_values = [1, 2, 3]
    name_values = [ "hello world", "📚📚📚📚⏳😀⌛😭", "áÁàÀãÃâÂéÉíÍóÓõÕúÚçÇ" ]
    amount_values = [123.45, 10, .1]

    println("")
    println("Printing out UTF-8 strings")

    while result.found

        value_id = Oracle.query_value(stmt, 1)
        value_name = Oracle.query_value(stmt, 2)
        value_amount = Oracle.query_value(stmt, 3)

        println(value_name[])

        @test id_values[iter] == value_id[]
        @test name_values[iter] == value_name[]
        @test amount_values[iter] == value_amount[]

        result = Oracle.fetch!(stmt)
        iter += 1
    end

    println("")

    Oracle.close!(stmt)

    simple_query(conn, "DROP TABLE TB_TEST_DATATYPES")
end

@testset "Timestamp" begin
    simple_query(conn, "CREATE TABLE TB_DATE ( DT DATE NULL )")
    simple_query(conn, "INSERT INTO TB_DATE (DT) VALUES ( TO_DATE('2018-12-31', 'yyyy-mm-dd') )")
    simple_query(conn, "INSERT INTO TB_DATE (DT) VALUES ( TO_DATE('2018-12-31 11:55:35 P.M.', 'yyyy-mm-dd HH:MI:SS A.M.') )")
    Oracle.commit!(conn)

    let
        dates = [ Date(2018, 12, 31), DateTime(2018, 12, 31, 23, 55, 35) ]

        row_number = 1

        for row in Oracle.query(conn, "SELECT DT FROM TB_DATE")
            @test row["DT"] == dates[row_number]
            @test isa(row["DT"], DateTime) # Oracle DATE columns stores DateTime up to seconds.

            row_number += 1
        end
    end

    simple_query(conn, "DROP TABLE TB_DATE")
end

@testset "Fetch Many" begin
    simple_query(conn, "CREATE TABLE TB_TEST_FETCH_MANY ( ID NUMBER(4,0) NULL, VAL NUMBER(4,0) NULL )")
    for i in 1:10
        simple_query(conn, "INSERT INTO TB_TEST_FETCH_MANY ( ID, VAL ) VALUES ( $i, $(10i))")
    end

    stmt = Oracle.Stmt(conn, "SELECT ID, VAL FROM TB_TEST_FETCH_MANY")
    result = Oracle.execute!(stmt)
    @test result.num_columns == 2

    fetch_rows_result = Oracle.fetch_rows!(stmt, 3)

    @test fetch_rows_result.buffer_row_index == 0
    @test fetch_rows_result.num_rows_fetched == 3
    @test fetch_rows_result.more_rows == 1

    value_id = Oracle.query_value(stmt, 1)
    value_val = Oracle.query_value(stmt, 2)

    @test value_id[] == 3
    @test value_val[] == 30

    @test value_id[-2] == 1
    @test value_val[-2] == 10

    @test value_id[-1] == 2
    @test value_val[-1] == 20

    @test value_id[0] == 3
    @test value_val[0] == 30

    Oracle.close!(stmt)

    simple_query(conn, "DROP TABLE TB_TEST_FETCH_MANY")
end

@testset "Cursor" begin
    simple_query(conn, "CREATE TABLE TB_TEST_CURSOR ( ID NUMBER(4,0) NULL, VAL NUMBER(15,0) NULL, VAL_FLT NUMBER(4,2), STR VARCHAR2(255) )")

    num_iterations = 10

    for i in 1:num_iterations
        simple_query(conn, "INSERT INTO TB_TEST_CURSOR ( ID, VAL, VAL_FLT, STR ) VALUES ( $i, $(10i), 10.01, '📚📚📚📚⏳😀⌛😭')")
    end

    row_number = 0
    for row in Oracle.query(conn, "SELECT * FROM TB_TEST_CURSOR", fetch_array_size=3)
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
    @test row_number == num_iterations

    simple_query(conn, "DROP TABLE TB_TEST_CURSOR")
end

@testset "Bind" begin

    @testset "bind int, flt, str, date" begin
        simple_query(conn, "CREATE TABLE TB_BIND ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)")

        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )")

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
            for row in Oracle.query(conn, "SELECT * FROM TB_BIND")
                @test row["ID"] == 1 + row_number
                @test row["FLT"] == 10.23 + row_number
                @test row["STR"] == "🍕 $row_number"
                @test row["DT"] == Date(2018,12,31) + Dates.Day(row_number)

                row_number += 1
            end
        end

        simple_query(conn, "DELETE FROM TB_BIND")

        stmt[:id, Int] = missing
        stmt[:flt, Float64] = missing
        stmt[:str, String] = missing
        stmt[:dt, Date] = missing
        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let
            row_number = 0
            for row in Oracle.query(conn, "SELECT * FROM TB_BIND")
                @test ismissing(row["ID"])
                @test ismissing(row["FLT"])
                @test ismissing(row["STR"])
                @test ismissing(row["DT"])
                row_number += 1
            end

            @test row_number == 1
        end

        simple_query(conn, "DROP TABLE TB_BIND")
    end

    @testset "Bind DateTime" begin
        simple_query(conn, "CREATE TABLE TB_BIND_TIMESTAMP ( TS TIMESTAMP NULL )")

        ts_now = Dates.now()
        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_TIMESTAMP ( TS ) VALUES ( :ts )")
        stmt[:ts] = ts_now
        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let row_number = 0
            for row in Oracle.query(conn, "SELECT TS FROM TB_BIND_TIMESTAMP")
                @test row["TS"] == ts_now
                @test isa(row["TS"], DateTime)
                row_number += 1
            end

            @test row_number == 1
        end

        simple_query(conn, "DROP TABLE TB_BIND_TIMESTAMP")
    end
end

#=
@testset "shutdown/startup" begin
    # The connection needs to have been established at least with authorization mode set to ORA_MODE_AUTH_SYSDBA or ORA_MODE_AUTH_SYSOPER
    Oracle.shutdown_database(conn)
    Oracle.startup_database(conn)
end
=#

#=
@testset "Pool" begin
    ctx = Oracle.Context()
    pool = Oracle.Pool(ctx, username, password, connect_string)
end
=#

Oracle.close!(conn)
