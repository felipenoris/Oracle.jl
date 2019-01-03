
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

@testset "Create structs" begin

    @testset "Client Version" begin
        v = Oracle.client_version(ctx)
        println("")
        println("### CLIENT VERSION ###")
        println(v)
        println("")
    end

    common_create_params = Oracle.dpiCommonCreateParams(ctx)
    pool_create_params = Oracle.dpiPoolCreateParams(ctx)
    conn_create_params = Oracle.dpiConnCreateParams(ctx)

    @testset "mutate conn_create_params" begin
        sysadmin_conn_create_params = Oracle.dpiConnCreateParams(ctx)
        sysadmin_conn_create_params.auth_mode = Oracle.DPI_MODE_AUTH_SYSDBA
        @test sysadmin_conn_create_params.auth_mode == Oracle.DPI_MODE_AUTH_SYSDBA
    end
end

@testset "Connection" begin
    conn = Oracle.Connection(ctx, username, password, connect_string)

    @testset "ping" begin
        Oracle.ping(conn)
    end

    @testset "Server Version" begin
        release, server_version = Oracle.server_version(conn)
        println("")
        println("### SERVER VERSION ###")
        println("release = $release")
        println("server_version = $server_version")
        println("")
    end

    @testset "Populate test table" begin
        simple_query(conn, "CREATE TABLE TB_TEST ( ID INT )")
        simple_query(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 1 )")
        simple_query(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 2 )")
        Oracle.commit!(conn)

        simple_query(conn, "INSERT INTO TB_TEST ( ID ) VALUES ( 3 )")
        Oracle.rollback!(conn)
    end

    @testset "Stmt" begin
        stmt = Oracle.Stmt(conn, "SELECT * FROM TB_TEST")
        num_columns = Oracle.execute!(stmt)
        @test num_columns == 1
    end

    @testset "Drop test table" begin
        simple_query(conn, "DROP TABLE TB_TEST")
    end

    #=
    @testset "shutdown/startup" begin
        # The connection needs to have been established at least with authorization mode set to DPI_MODE_AUTH_SYSDBA or DPI_MODE_AUTH_SYSOPER
        Oracle.shutdown_database(conn)
        Oracle.startup_database(conn)
    end
    =#
end

#=
@testset "Pool" begin
    ctx = Oracle.Context()
    pool = Oracle.Pool(ctx, username, password, connect_string)
end
=#
