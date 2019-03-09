
__precompile__(true)
module Oracle

include("compat.jl")

const DEPS_FILE = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_FILE)
    error("Oracle.jl is not installed properly, run Pkg.build(\"Oracle\") and restart Julia.")
end
include(DEPS_FILE)

include("oranumbers/oranumbers.jl")
import .OraNumbers.OraNumber

include("macros.jl")
include("constants.jl")
include("enums.jl")
include("types.jl")
include("odpi.jl")
include("timestamps.jl")
include("ora_timestamp.jl")
include("context.jl")
include("connection.jl")
include("oracle_value.jl")
include("stmt.jl")
include("bind.jl")
include("lob.jl")
include("cursor.jl")
include("pool.jl")
include("variable.jl")
include("deprecated.jl")

function __init__()
    # this function is defined in DEPS_FILE
    check_deps()

    # check size of structs affected by C unions
    @assert sizeof(OraDataBuffer) == sizeof_dpiDataBuffer()
    @assert sizeof(OraData) == sizeof_dpiData()
    @assert sizeof(OraPoolCreateParams) == sizeof_dpiPoolCreateParams()
    @assert sizeof(OraConnCreateParams) == sizeof_dpiConnCreateParams()
    @assert sizeof(OraQueryInfo) == sizeof_dpiQueryInfo()
    @assert sizeof(OraNumber) == sizeof_dpiNumber()

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
