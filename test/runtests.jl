
import Oracle

if VERSION < v"0.7-"
    using Base.Test
else
    using Test
#    using Dates
end

@assert isfile(joinpath(@__DIR__, "credentials.jl")) """
Before running tests, create a file `test/credentials.jl` with the content:

username = "your-username"
password = "your-password"
connect_string = "your-connect-string"
"""
include("credentials.jl")

simple_query(conn::Oracle.Connection, sql::String) = Oracle.execute!(Oracle.Stmt(conn, sql))

ctx = Oracle.Context()
conn = Oracle.Connection(ctx, username, password, connect_string)

# Client Version
let
    v = Oracle.client_version(ctx)
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
    println("")
end

@testset "Create structs" begin
    common_create_params = Oracle.dpiCommonCreateParams(ctx)
    pool_create_params = Oracle.dpiPoolCreateParams(ctx)
    conn_create_params = Oracle.dpiConnCreateParams(ctx)

    @testset "mutate conn_create_params" begin
        sysadmin_conn_create_params = Oracle.dpiConnCreateParams(ctx)
        sysadmin_conn_create_params.auth_mode = Oracle.DPI_MODE_AUTH_SYSDBA
        @test sysadmin_conn_create_params.auth_mode == Oracle.DPI_MODE_AUTH_SYSDBA
    end
end

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
    stmt_info = Oracle.dpiStmtInfo(stmt)
    @test stmt_info.is_query == 1
    @test stmt_info.is_DDL == 0
    @test stmt_info.is_DML == 0
    @test stmt_info.statement_type == Oracle.DPI_STMT_TYPE_SELECT

    num_columns = Oracle.execute!(stmt)
    @test num_columns == 1
    @test num_columns == Oracle.num_query_columns(stmt)

    query_info = Oracle.dpiQueryInfo(stmt, 1)
    @test Oracle.column_name(query_info) == "ID"
end

@testset "fetch" begin
    stmt = Oracle.Stmt(conn, "SELECT ID FROM TB_TEST")
    Oracle.execute!(stmt)

    found, buffer_row_index = Oracle.fetch!(stmt)
    @test found

    value = Oracle.query_value(stmt, 1)
    @test !Oracle.is_null(value)
    @test value[] == 1.0
    @test isa(value[], Float64)

    found, buffer_row_index = Oracle.fetch!(stmt)
    @test found

    value = Oracle.query_value(stmt, 1)
    @test Oracle.is_null(value)
    @test ismissing(value[])
    @test isa(value[], Missing)
end

@testset "Drop" begin
    simple_query(conn, "DROP TABLE TB_TEST")
end

@testset "parse data" begin
    simple_query(conn, "CREATE TABLE TB_TEST_DATATYPES ( ID NUMBER(38,0) NULL, name VARCHAR2(30) NULL,  amount NUMBER(15,2) NULL)")

    simple_query(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 1, 'hello world', 123.45 )")
    simple_query(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 2, 'the bomb 💣', 10 )")
    simple_query(conn, "INSERT INTO TB_TEST_DATATYPES ( ID, name, amount ) VALUES ( 3, 'ãéí', .1 )")
    Oracle.commit!(conn)

    stmt = Oracle.Stmt(conn, "SELECT ID, name, amount FROM TB_TEST_DATATYPES")
    num_columns = Oracle.execute!(stmt)
    @test num_columns == 3

    found, buffer_row_index = Oracle.fetch!(stmt)
    @test found

    while found

        value_id = Oracle.query_value(stmt, 1)
        value_name = Oracle.query_value(stmt, 2)
        value_amount = Oracle.query_value(stmt, 3)

        println("value_id = ", value_id[])
        println("value_name = ", value_name[])
        println("value amount = ", value_amount[])

        found, buffer_row_index = Oracle.fetch!(stmt)
    end

    simple_query(conn, "DROP TABLE TB_TEST_DATATYPES")
end

#=
@testset "shutdown/startup" begin
    # The connection needs to have been established at least with authorization mode set to DPI_MODE_AUTH_SYSDBA or DPI_MODE_AUTH_SYSOPER
    Oracle.shutdown_database(conn)
    Oracle.startup_database(conn)
end
=#

@testset "Pool" begin
    ctx = Oracle.Context()
    pool = Oracle.Pool(ctx, username, password, connect_string)
end
