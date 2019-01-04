
function dpiPoolCreateParams(ctx::Context)
    dpi_pool_create_params_ref = Ref{dpiPoolCreateParams}()
    dpi_result = dpiContext_initPoolCreateParams(ctx.handle, dpi_pool_create_params_ref)
    error_check(ctx, dpi_result)
    return dpi_pool_create_params_ref[]
end

function Pool(ctx::Context, user::String, password::String, connect_string::String; common_params::dpiCommonCreateParams=dpiCommonCreateParams(ctx), pool_create_params::dpiPoolCreateParams=dpiPoolCreateParams(ctx))
    dpi_pool_handle_ref = Ref{Ptr{Cvoid}}()
    dpi_result = dpiPool_create(ctx.handle, user, password, connect_string, Ref(common_params), Ref(pool_create_params), dpi_pool_handle_ref)
    error_check(ctx, dpi_result)
    return Pool(ctx, dpi_pool_handle_ref[])
end
