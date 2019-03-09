
function Pool(ctx::Context, user::String, password::String, connect_string::String, common_params::CommonCreateParams, pool_create_params::OraPoolCreateParams)
    ora_common_params = OraCommonCreateParams(ctx, common_params)
    dpi_pool_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiPool_create(ctx.handle, user, password, connect_string, Ref(ora_common_params), Ref(pool_create_params), dpi_pool_handle_ref)
    error_check(ctx, result)

    # retrieves pool name from OraPoolCreateParams
    @assert pool_create_params.out_pool_name != C_NULL "Failed to create a Pool: no pool name was returned."
    pool_name = unsafe_string(pool_create_params.out_pool_name, pool_create_params.out_pool_name_length)

    return Pool(ctx, dpi_pool_handle_ref[], pool_name)
end

function Pool(ctx::Context, user::String, password::String, connect_string::String;
            encoding::AbstractString=DEFAULT_CONNECTION_ENCODING,
            nencoding::AbstractString=DEFAULT_CONNECTION_NENCODING,
            create_mode::Union{Nothing, OraCreateMode}=nothing,
            edition::Union{Nothing, String}=nothing,
            driver_name::Union{Nothing, String}=nothing,
            min_sessions::Union{Nothing, Integer}=nothing,
            max_sessions::Union{Nothing, Integer}=nothing,
            session_increment::Union{Nothing, Integer}=nothing,
            ping_interval::Union{Nothing, Integer}=nothing,
            ping_timeout::Union{Nothing, Integer}=nothing,
            homogeneous::Union{Nothing, Bool}=nothing,
            external_auth::Union{Nothing, Bool}=nothing,
            get_mode::Union{Nothing, OraPoolGetMode}=nothing,
            timeout::Union{Nothing, Integer}=nothing,
            wait_timeout::Union{Nothing, Integer}=nothing,
            max_lifetime_session::Union{Nothing, Integer}=nothing
        )

    function EmptyOraPoolCreateParams(ctx::Context)
        pool_create_params_ref = Ref{OraPoolCreateParams}(OraPoolCreateParams(UInt32(1), UInt32(1), UInt32(0), Int32(60), Int32(5000), Int32(1), Int32(0), ORA_MODE_POOL_GET_NOWAIT, C_NULL, UInt32(0), UInt32(0), UInt32(0), UInt32(0), C_NULL, 0))
        result = dpiContext_initPoolCreateParams(ctx.handle, pool_create_params_ref)
        error_check(ctx, result)
        return pool_create_params_ref[]
    end

    pool_create_params = EmptyOraPoolCreateParams(ctx)

    # parse optional pool parameters
    @parse_opt_field_param(pool_create_params, min_sessions, UInt32)
    @parse_opt_field_param(pool_create_params, max_sessions, UInt32)
    @parse_opt_field_param(pool_create_params, session_increment, UInt32)
    @parse_opt_field_param(pool_create_params, ping_interval, Int32)
    @parse_opt_field_param(pool_create_params, ping_timeout, Int32)
    @parse_opt_field_param(pool_create_params, homogeneous, Int32)
    @parse_opt_field_param(pool_create_params, external_auth, Int32)
    @parse_opt_field_param(pool_create_params, get_mode)
    @parse_opt_field_param(pool_create_params, timeout, UInt32)
    @parse_opt_field_param(pool_create_params, wait_timeout, UInt32)
    @parse_opt_field_param(pool_create_params, max_lifetime_session, UInt32)

    common_params = CommonCreateParams(create_mode, encoding, nencoding, edition, driver_name)
    return Pool(ctx, user, password, connect_string, common_params, pool_create_params)
end

function Pool(user::String, password::String, connect_string::String;
            encoding::AbstractString=DEFAULT_CONNECTION_ENCODING,
            nencoding::AbstractString=DEFAULT_CONNECTION_NENCODING,
            create_mode::Union{Nothing, OraCreateMode}=nothing,
            edition::Union{Nothing, String}=nothing,
            driver_name::Union{Nothing, String}=nothing,
            min_sessions::Union{Nothing, Integer}=nothing,
            max_sessions::Union{Nothing, Integer}=nothing,
            session_increment::Union{Nothing, Integer}=nothing,
            ping_interval::Union{Nothing, Integer}=nothing,
            ping_timeout::Union{Nothing, Integer}=nothing,
            homogeneous::Union{Nothing, Bool}=nothing,
            external_auth::Union{Nothing, Bool}=nothing,
            get_mode::Union{Nothing, OraPoolGetMode}=nothing,
            timeout::Union{Nothing, Integer}=nothing,
            wait_timeout::Union{Nothing, Integer}=nothing,
            max_lifetime_session::Union{Nothing, Integer}=nothing
        )
    return Pool(Context(), user, password, connect_string,
            encoding=encoding,
            nencoding=nencoding,
            create_mode=create_mode,
            edition=edition,
            driver_name=driver_name,
            min_sessions=min_sessions,
            max_sessions=max_sessions,
            session_increment=session_increment,
            ping_interval=ping_interval,
            ping_timeout=ping_timeout,
            homogeneous=homogeneous,
            external_auth=external_auth,
            get_mode=get_mode,
            timeout=timeout,
            wait_timeout=wait_timeout,
            max_lifetime_session=max_lifetime_session
        )
end

function pool_get_mode(pool::Pool) :: OraPoolGetMode
    pool_get_mode_ref = Ref{OraPoolGetMode}()
    result = dpiPool_getGetMode(pool.handle, pool_get_mode_ref)
    error_check(context(pool), result)
    return pool_get_mode_ref[]
end

function Connection(pool::Pool; auth_mode::OraAuthMode=ORA_MODE_AUTH_DEFAULT)
    conn_create_params = ConnCreateParams(auth_mode, pool)
    ora_conn_create_params = OraConnCreateParams(context(pool), conn_create_params)
    connection_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiPool_acquireConnection(pool.handle, Ref(ora_conn_create_params), connection_handle_ref)
    error_check(context(pool), result)
    return Connection(context(pool), connection_handle_ref[], pool)
end

function close(pool::Pool; close_mode::OraPoolCloseMode=ORA_MODE_POOL_CLOSE_DEFAULT)
    result = dpiPool_close(pool.handle, close_mode)
    error_check(context(pool), result)
    nothing
end
