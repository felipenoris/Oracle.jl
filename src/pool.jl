
function OraPoolCreateParams(ctx::Context)
    pool_create_params_ref = Ref{OraPoolCreateParams}()
    result = dpiContext_initPoolCreateParams(ctx.handle, pool_create_params_ref)
    error_check(ctx, result)
    return pool_create_params_ref[]
end

function Pool(ctx::Context, user::String, password::String, connect_string::String; common_params::OraCommonCreateParams=OraCommonCreateParams(ctx), pool_create_params::OraPoolCreateParams=OraPoolCreateParams(ctx))
    dpi_pool_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiPool_create(ctx.handle, user, password, connect_string, Ref(common_params), Ref(pool_create_params), dpi_pool_handle_ref)
    error_check(ctx, result)
    return Pool(ctx, dpi_pool_handle_ref[])
end
