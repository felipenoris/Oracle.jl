
module Oracle

const DEPS_FILE = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_FILE)
    error("Oracle.jl is not installed properly, run Pkg.build(\"Oracle\") and restart Julia.")
end
include(DEPS_FILE)

include("types.jl")
include("odpi.jl")

function __init__()
    check_deps() # defined in DEPS_FILE
end

@inline function error_check(ctx::Context, dpi_result::dpiResult)
    if dpi_result == DPI_FAILURE
        error_info_ref = Ref{dpiErrorInfo}()
        dpiContext_getError(ctx.handle, error_info_ref)
        error_info = error_info_ref[]
        throw(error_info)
    end
    @assert dpi_result == DPI_SUCCESS

    nothing
end

function Pool(ctx::Context, user::String, password::String, connect_string::String; common_params::dpiCommonCreateParams=dpiCommonCreateParams(ctx), pool_create_params::dpiPoolCreateParams=dpiPoolCreateParams(ctx))
    dpi_pool_handle_ref = Ref{Ptr{Cvoid}}()
    dpi_result = dpiPool_create(ctx.handle, user, password, connect_string, Ref(common_params), Ref(pool_create_params), dpi_pool_handle_ref)
    error_check(ctx, dpi_result)

    return Pool(dpi_pool_handle_ref[])
end

function dpiConnCreateParams(ctx::Context)
    new_conn_create_params = dpiConnCreateParams(DPI_MODE_AUTH_DEFAULT, C_NULL, 0, DPI_PURITY_DEFAULT, C_NULL, 0, C_NULL, 0, 0, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL, 0, 0, C_NULL, 0, C_NULL, 0)
    conn_create_params_ref = Ref{dpiConnCreateParams}(new_conn_create_params)
    dpi_result = dpiContext_initConnCreateParams(ctx.handle, conn_create_params_ref)
    error_check(ctx, dpi_result)
    return conn_create_params_ref[]
end

function Connection(ctx::Context, user::String, password::String, connect_string::String; common_params::dpiCommonCreateParams=dpiCommonCreateParams(ctx), conn_create_params::dpiConnCreateParams=dpiConnCreateParams(ctx))
    conn_handle_ref = Ref{Ptr{Cvoid}}()
    dpi_result = dpiConn_create(ctx.handle, user, password, connect_string, Ref(common_params), Ref(conn_create_params), conn_handle_ref)
    error_check(ctx, dpi_result)
    return Connection(ctx, conn_handle_ref[])
end

function Context()
    error_info_ref = Ref{dpiErrorInfo}()
    context_handle_ref = Ref{Ptr{Cvoid}}()
    dpi_result = dpiContext_create(DPI_MAJOR_VERSION, DPI_MINOR_VERSION, context_handle_ref, error_info_ref)

    if dpi_result == DPI_FAILURE
        error_info = error_info_ref[]
        throw(error_info)
    end
    @assert dpi_result == DPI_SUCCESS

    return Context(context_handle_ref[])
end

function client_version(ctx::Context) :: dpiVersionInfo
    version_info_ref = Ref{dpiVersionInfo}()
    dpiContext_getClientVersion(ctx.handle, version_info_ref)
    return version_info_ref[]
end

function server_version(conn::Connection)
    release_string_ptr_ref = Ref{Ptr{UInt8}}()
    release_string_length_ref = Ref{UInt32}()
    version_info_ref = Ref{dpiVersionInfo}()
    dpiConn_getServerVersion(conn.handle, release_string_ptr_ref, release_string_length_ref, version_info_ref)

    release_string = unsafe_string(release_string_ptr_ref[], release_string_length_ref[])
    return (release_string, version_info_ref[])
end

function ping(conn::Connection)
    dpi_result = dpiConn_ping(conn.handle)
    error_check(conn.context, dpi_result)
    nothing
end

function startup_database(conn::Connection, startup_mode::dpiStartupMode=DPI_MODE_STARTUP_DEFAULT)
    dpi_result = dpiConn_startupDatabase(conn.handle, startup_mode)
    error_check(conn.context, dpi_result)
    nothing
end

function shutdown_database(conn::Connection, shutdown_mode::dpiShutdownMode=DPI_MODE_SHUTDOWN_DEFAULT)
    dpi_result = dpiConn_shutdownDatabase(conn.handle, shutdown_mode)
    error_check(conn.context, dpi_result)
    nothing
end

function dpiCommonCreateParams(ctx::Context)
    dpi_common_create_params_ref = Ref{dpiCommonCreateParams}()
    dpi_result = dpiContext_initCommonCreateParams(ctx.handle, dpi_common_create_params_ref)
    error_check(ctx, dpi_result)
    return dpi_common_create_params_ref[]
end

function dpiPoolCreateParams(ctx::Context)
    dpi_pool_create_params_ref = Ref{dpiPoolCreateParams}()
    dpi_result = dpiContext_initPoolCreateParams(ctx.handle, dpi_pool_create_params_ref)
    error_check(ctx, dpi_result)
    return dpi_pool_create_params_ref[]
end

end # module Oracle
