module Oracle

const DEPS_FILE = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_FILE)
    error("Oracle.jl is not installed properly, run Pkg.build(\"Oracle\") and restart Julia.")
end
include(DEPS_FILE)

function __init__()
    check_deps() # defined in DEPS_FILE
end

greet() = print("Hello World!")

end # module
