
function OraConnCreateParams(ctx::Context)
    new_conn_create_params = OraConnCreateParams(ORA_MODE_AUTH_DEFAULT, C_NULL, 0, ORA_PURITY_DEFAULT, C_NULL, 0, C_NULL, 0, 0, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL, 0, 0, C_NULL, 0, C_NULL, 0)
    conn_create_params_ref = Ref{OraConnCreateParams}(new_conn_create_params)
    result = dpiContext_initConnCreateParams(ctx.handle, conn_create_params_ref)
    error_check(ctx, result)
    return conn_create_params_ref[]
end

function Connection(ctx::Context, user::String, password::String, connect_string::String; common_params::OraCommonCreateParams=OraCommonCreateParams(ctx), conn_create_params::OraConnCreateParams=OraConnCreateParams(ctx))
    conn_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_create(ctx.handle, user, password, connect_string, Ref(common_params), Ref(conn_create_params), conn_handle_ref)
    error_check(ctx, result)
    return Connection(ctx, conn_handle_ref[])
end

function Connection(user::String, password::String, connect_string::String; common_params::OraCommonCreateParams=OraCommonCreateParams(ctx), conn_create_params::OraConnCreateParams=OraConnCreateParams(ctx))
    return Connection(Context(), user, password, connect_string; common_params=common_params, conn_create_params=conn_create_params)
end

function server_version(conn::Connection)
    release_string_ptr_ref = Ref{Ptr{UInt8}}()
    release_string_length_ref = Ref{UInt32}()
    version_info_ref = Ref{OraVersionInfo}()
    dpiConn_getServerVersion(conn.handle, release_string_ptr_ref, release_string_length_ref, version_info_ref)

    release_string = unsafe_string(release_string_ptr_ref[], release_string_length_ref[])
    return (release_string, version_info_ref[])
end

function ping(conn::Connection)
    result = dpiConn_ping(conn.handle)
    error_check(conn.context, result)
    nothing
end

function startup_database(conn::Connection, startup_mode::OraStartupMode=ORA_MODE_STARTUP_DEFAULT)
    result = dpiConn_startupDatabase(conn.handle, startup_mode)
    error_check(conn.context, result)
    nothing
end

function shutdown_database(conn::Connection, shutdown_mode::OraShutdownMode=ORA_MODE_SHUTDOWN_DEFAULT)
    result = dpiConn_shutdownDatabase(conn.handle, shutdown_mode)
    error_check(conn.context, result)
    nothing
end

function commit!(conn::Connection)
    result = dpiConn_commit(conn.handle)
    error_check(conn.context, result)
    nothing
end

function rollback!(conn::Connection)
    result = dpiConn_rollback(conn.handle)
    error_check(conn.context, result)
    nothing
end

function close!(conn::Connection; close_mode::OraConnCloseMode=ORA_MODE_CONN_CLOSE_DEFAULT, tag::String="")
    result = dpiConn_close(conn.handle, close_mode=close_mode, tag=tag)
    error_check(conn.context, result)
    nothing
end
