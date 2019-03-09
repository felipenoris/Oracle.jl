
import Oracle
using Dates

@assert VERSION >= v"0.7-"

@assert isfile(joinpath(@__DIR__, "..", "test","credentials.jl")) """
Before running tests, create a file `test/credentials.jl` with the content:

username = "your-username"
password = "your-password"
connect_string = "your-connect-string"
auth_mode = Oracle.ORA_MODE_AUTH_DEFAULT # or Oracle.ORA_MODE_AUTH_SYSDBA if user is SYSDBA
"""
include(joinpath(@__DIR__, "..", "test","credentials.jl"))

conn = Oracle.Connection(username, password, connect_string, auth_mode=auth_mode)

Oracle.execute(conn, "CREATE TABLE TB_BENCH_EXECUTE_MANY ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL )")

let
    # JIT
    stmt = Oracle.Stmt(conn, "INSERT INTO TB_BENCH_EXECUTE_MANY ( ID, FLT ) VALUES ( :1, :2 )")
    stmt[1] = 1
    stmt[2] = 0.5
    Oracle.execute(stmt)
    Oracle.rollback(conn)
    Oracle.close(stmt)
end

let
    # JIT
    Oracle.execute(conn, "INSERT INTO TB_BENCH_EXECUTE_MANY ( ID, FLT ) VALUES ( :1, :2 )", [ [1, 2], [0.5, 1.5] ])
    Oracle.rollback(conn)
end

NUM_ROWS = 1_000

column_1 = [ i for i in 1:NUM_ROWS ]
column_2 = .5 * column_1

println("one row at a time")
@time let
    stmt = Oracle.Stmt(conn, "INSERT INTO TB_BENCH_EXECUTE_MANY ( ID, FLT ) VALUES ( :1, :2 )")
    for i in 1:NUM_ROWS
        stmt[1] = column_1[i]
        stmt[2] = column_2[i]
        Oracle.execute(stmt)
    end
    Oracle.rollback(conn)
    Oracle.close(stmt)
end

println("execute many")
@time let
    Oracle.execute(conn, "INSERT INTO TB_BENCH_EXECUTE_MANY ( ID, FLT ) VALUES ( :1, :2 )", [ column_1, column_2 ])
    Oracle.rollback(conn)
end

Oracle.execute(conn, "DROP TABLE TB_BENCH_EXECUTE_MANY")
