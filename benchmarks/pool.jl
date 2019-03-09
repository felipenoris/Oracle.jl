
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

const NUM_CONNECTIONS = 10

let
    # JIT
    ctx = Oracle.Context()
    conn = Oracle.Connection(ctx, username, password, connect_string)
    pool = Oracle.Pool(ctx, username, password, connect_string)

    Oracle.close(conn)
    Oracle.close(pool)
end

println("Create $NUM_CONNECTIONS Connections")
@time let
    ctx = Oracle.Context()
    v = Vector{Oracle.Connection}()

    for i in 1:NUM_CONNECTIONS
        push!(v, Oracle.Connection(ctx, username, password, connect_string))
    end

    for c in v
        Oracle.close(c)
    end
end

let
    ctx = Oracle.Context()
    println("Time to create a Pool")
    @time pool = Oracle.Pool(ctx, username, password, connect_string, max_sessions=NUM_CONNECTIONS, session_increment=1)

    println("Time to acquire $NUM_CONNECTIONS connections from the pool 1st time")

    @time let
        v = Vector{Oracle.Connection}()

        for i in 1:NUM_CONNECTIONS
            push!(v, Oracle.Connection(pool))
        end

        for c in v
            Oracle.close(c)
        end
    end

    println("Time to acquire $NUM_CONNECTIONS connections from the pool 2nd time")

    @time let
        v = Vector{Oracle.Connection}()

        for i in 1:NUM_CONNECTIONS
            push!(v, Oracle.Connection(pool))
        end

        for c in v
            Oracle.close(c)
        end
    end

    Oracle.close(pool)
end
