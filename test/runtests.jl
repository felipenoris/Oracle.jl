
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

@testset "ping" begin
    Oracle.ping(conn)
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

    Oracle.execute!(stmt)
    @test Oracle.num_columns(stmt) == 1

    query_info = Oracle.OraQueryInfo(stmt, 1)
    @test Oracle.column_name(query_info) == "ID"

    Oracle.close!(stmt)
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

    Oracle.close!(stmt)
end

@testset "Drop" begin
    Oracle.execute!(conn, "DROP TABLE TB_TEST")
end

@testset "parse data" begin
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
    Oracle.execute!(conn, "DROP TABLE TB_TEST_DATATYPES")
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

@testset "Fetch Many" begin
    Oracle.execute!(conn, "CREATE TABLE TB_TEST_FETCH_MANY ( ID NUMBER(4,0) NULL, VAL NUMBER(4,0) NULL )")
    for i in 1:10
        Oracle.execute!(conn, "INSERT INTO TB_TEST_FETCH_MANY ( ID, VAL ) VALUES ( $i, $(10i))")
    end

    stmt = Oracle.Stmt(conn, "SELECT ID, VAL FROM TB_TEST_FETCH_MANY")
    Oracle.execute!(stmt)
    @test Oracle.num_columns(stmt) == 2

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
    Oracle.execute!(conn, "DROP TABLE TB_TEST_FETCH_MANY")
end

@testset "Cursor" begin
    Oracle.execute!(conn, "CREATE TABLE TB_TEST_CURSOR ( ID NUMBER(4,0) NULL, VAL NUMBER(15,0) NULL, VAL_FLT NUMBER(4,2), STR VARCHAR2(255) )")

    num_iterations = 10

    for i in 1:num_iterations
        Oracle.execute!(conn, "INSERT INTO TB_TEST_CURSOR ( ID, VAL, VAL_FLT, STR ) VALUES ( $i, $(10i), 10.01, '📚📚📚📚⏳😀⌛😭')")
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

        if VERSION >= v"0.7-"
            # testing only on Julia v1.0
            @test_throws AssertionError stmt[:dt] = missing
            @test_throws AssertionError stmt[:dt, Int] = 1
        end

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

        if VERSION >= v"0.7-"
            # testing only on Julia v1.0
            @test_throws AssertionError stmt[0] = 10
            @test_throws AssertionError stmt[5] = 10
        end

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

        if VERSION >= v"0.7-"
            # testing only on Julia v1.0
            @test_throws AssertionError stmt[:dt] = missing
            @test_throws AssertionError stmt[:dt, Int] = 1
        end

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

    @testset "Bind DateTime" begin
        Oracle.execute!(conn, "CREATE TABLE TB_BIND_TIMESTAMP ( TS TIMESTAMP NULL )")

        ts_now = Dates.now()
        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_TIMESTAMP ( TS ) VALUES ( :ts )")
        stmt[:ts] = ts_now
        Oracle.execute!(stmt)
        Oracle.commit!(conn)

        let row_number = 0

            Oracle.query(conn, "SELECT TS FROM TB_BIND_TIMESTAMP") do cursor
                for row in cursor
                    @test row["TS"] == ts_now
                    @test isa(row["TS"], DateTime)
                    row_number += 1
                end
            end

            @test row_number == 1
        end

        Oracle.close!(stmt)
        Oracle.execute!(conn, "DROP TABLE TB_BIND_TIMESTAMP")
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
