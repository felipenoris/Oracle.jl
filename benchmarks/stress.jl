
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

const NUM_ITERATIONS = 10

function bench()
    conn = Oracle.Connection(username, password, connect_string, auth_mode=auth_mode)

    try

        Oracle.execute(conn, "CREATE TABLE TB_BIND_BY_NAME ( ID NUMBER(15,0) NULL, FLT NUMBER(15,4) NULL, STR VARCHAR(255) NULL, DT DATE NULL)")

        stmt = Oracle.Stmt(conn, "INSERT INTO TB_BIND_BY_NAME ( ID, FLT, STR, DT ) VALUES ( :id, :flt, :str, :dt )")
        @assert stmt.bind_count == 4

        for i in 1:10
            stmt[:id] = 1 + i
            stmt[:flt] = 10.23 + i
            stmt[:str] = "🍕 $i"
            stmt[:dt] = Date(2018,12,31) + Dates.Day(i)
            Oracle.execute(stmt)
        end
        Oracle.commit(conn)

        let
            row_number = 1
            Oracle.query(conn, "SELECT * FROM TB_BIND_BY_NAME") do cursor
                for row in cursor
                    @assert row["ID"] == 1 + row_number
                    @assert row["FLT"] == 10.23 + row_number
                    @assert row["STR"] == "🍕 $row_number"
                    @assert row["DT"] == Date(2018,12,31) + Dates.Day(row_number)

                    row_number += 1
                end
            end
        end

        Oracle.execute(conn, "DELETE FROM TB_BIND_BY_NAME")

        stmt[:id, Int] = missing
        stmt[:flt, Float64] = missing
        stmt[:str, String] = missing
        stmt[:dt, Date] = missing

        Oracle.execute(stmt)
        Oracle.commit(conn)

        let
            row_number = 0
            Oracle.query(conn, "SELECT * FROM TB_BIND_BY_NAME") do cursor
                for row in cursor
                    @assert ismissing(row["ID"])
                    @assert ismissing(row["FLT"])
                    @assert ismissing(row["STR"])
                    @assert ismissing(row["DT"])
                    row_number += 1
                end
            end

            @assert row_number == 1
        end

        Oracle.close(stmt)
        Oracle.execute(conn, "DROP TABLE TB_BIND_BY_NAME")

    finally
        Oracle.close(conn)
    end
end

function main()
    for iter in 1:NUM_ITERATIONS
        bench()
        println("Iteration $iter.")
        GC.gc()
    end
end

main()
