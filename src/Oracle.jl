
module Oracle

# Compat
@static if VERSION < v"0.7-"
    const Nothing = Void
    const Cvoid   = Void
else
    #using Dates
end

function undef_vector(::Type{T}, len::Integer) where T
    @static if VERSION < v"0.7-"
        Vector{T}(len)
    else
        Vector{T}(undef, len)
    end
end

const DEPS_FILE = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_FILE)
    error("Oracle.jl is not installed properly, run Pkg.build(\"Oracle\") and restart Julia.")
end
include(DEPS_FILE)

include("types.jl")
include("odpi.jl")
include("context.jl")
include("connection.jl")
include("stmt.jl")
include("pool.jl")

function __init__()
    check_deps() # defined in DEPS_FILE
end

@inline function error_check(ctx::Context, dpi_result::dpiResult)
    if dpi_result == DPI_FAILURE
        error_info_ref = Ref{dpiErrorInfo}()
        dpiContext_getError(ctx.handle, error_info_ref)
        error_info = error_info_ref[]
        throw(error_info)
    end
    @assert dpi_result == DPI_SUCCESS

    nothing
end

end # module Oracle
