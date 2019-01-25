
__precompile__(true)
module Oracle

include("compat.jl")

const DEPS_FILE = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_FILE)
    error("Oracle.jl is not installed properly, run Pkg.build(\"Oracle\") and restart Julia.")
end
include(DEPS_FILE)

include("constants.jl")
include("enums.jl")
include("types.jl")
include("odpi.jl")
include("context.jl")
include("connection.jl")
include("stmt.jl")
include("values.jl")
include("cursor.jl")
include("pool.jl")
include("variable.jl")

function __init__()
    # this function is defined in DEPS_FILE
    check_deps()

    # check size of structs affected by C unions
    @assert sizeof(OraDataBuffer) == sizeof_dpiDataBuffer()
    @assert sizeof(OraData) == sizeof_dpiData()

    # Checks that ODPI-C works
    ctx = Context()
    destroy!(ctx)
end

@inline function error_check(ctx::Context, result::OraResult)
    if result == ORA_FAILURE
        error_info_ref = Ref{OraErrorInfo}()
        dpiContext_getError(ctx.handle, error_info_ref)
        error_info = error_info_ref[]
        throw(error_info)
    end
    @assert result == ORA_SUCCESS

    nothing
end

end # module Oracle
