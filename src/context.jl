
context(conn::Connection) = conn.context
context(stmt::Stmt) = context(stmt.connection)

function Context()
    error_info_ref = Ref{OraErrorInfo}()
    context_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiContext_create(ORA_MAJOR_VERSION, ORA_MINOR_VERSION, context_handle_ref, error_info_ref)

    if result == ORA_FAILURE
        error_info = error_info_ref[]
        throw(error_info)
    end
    @assert result == ORA_SUCCESS

    return Context(context_handle_ref[])
end

function client_version(ctx::Context) :: OraVersionInfo
    version_info_ref = Ref{OraVersionInfo}()
    dpiContext_getClientVersion(ctx.handle, version_info_ref)
    return version_info_ref[]
end

function OraCommonCreateParams(ctx::Context)
    common_create_params_ref = Ref{OraCommonCreateParams}(OraCommonCreateParams(ORA_MODE_CREATE_DEFAULT, C_NULL, C_NULL, C_NULL, 0, C_NULL, 0))
    result = dpiContext_initCommonCreateParams(ctx.handle, common_create_params_ref)
    error_check(ctx, result)
    return common_create_params_ref[]
end
