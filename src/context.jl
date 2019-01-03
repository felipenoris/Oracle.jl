
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

function dpiCommonCreateParams(ctx::Context)
    dpi_common_create_params_ref = Ref{dpiCommonCreateParams}(dpiCommonCreateParams(DPI_MODE_CREATE_DEFAULT, C_NULL, C_NULL, C_NULL, 0, C_NULL, 0))
    dpi_result = dpiContext_initCommonCreateParams(ctx.handle, dpi_common_create_params_ref)
    error_check(ctx, dpi_result)
    return dpi_common_create_params_ref[]
end
