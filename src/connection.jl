
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

function Connection(user::String, password::String, connect_string::String; common_params::dpiCommonCreateParams=dpiCommonCreateParams(ctx), conn_create_params::dpiConnCreateParams=dpiConnCreateParams(ctx))
    return Connection(Context(), user, password, connect_string; common_params=common_params, conn_create_params=conn_create_params)
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
