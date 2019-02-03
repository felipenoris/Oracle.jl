
@static if VERSION < v"0.7-"
    const Nothing = Void
    const Cvoid   = Void
    using Missings

    firstindex(s::AbstractString) = start(s)
    lastindex(s::AbstractString) = endof(s)

else
    using Dates
end

@inline function undef_vector(::Type{T}, len::Integer) where {T}
    @static if VERSION < v"0.7-"
        Vector{T}(len)
    else
        Vector{T}(undef, len)
    end
end

#
# Code snippets from https://github.com/JuliaLang/Compat.jl
#

function _compat(ex::Expr)
    if VERSION < v"0.7.0-DEV.2562"
        if ex.head == :call && ex.args[1] == :finalizer
            ex.args[2], ex.args[3] = ex.args[3], ex.args[2]
        end
    end
    return Expr(ex.head, map(_compat, ex.args)...)
end

_compat(ex) = ex

macro compat(ex)
    esc(_compat(ex))
end
