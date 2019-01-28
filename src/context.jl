
@inline context(ctx::Context) = ctx
@inline context(conn::Connection) = conn.context
@inline context(stmt::Stmt) = context(stmt.connection)
@inline context(pool::Pool) = pool.context
@inline context(variable::Variable) = context(variable.connection)
@inline context(lob::Lob) = context(lob.parent)
@inline context(v::JuliaOracleValue) = v.context
@inline context(v::ExternOracleValue) = context(v.parent)

function Context()
    error_info_ref = Ref{OraErrorInfo}()
    context_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiContext_create(ORA_MAJOR_VERSION, ORA_MINOR_VERSION, context_handle_ref, error_info_ref)

    if result == ORA_FAILURE
        error_info = error_info_ref[]

        if error_info.code == 0
            error_message = unsafe_string(error_info.message, error_info.message_length)

            if startswith(error_message, "DPI-1020")
                error("$error_message. Please, run `Pkg.build(\"Oracle\")` and restart Julia.")
            else
                throw(error_info)
            end
        end

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
