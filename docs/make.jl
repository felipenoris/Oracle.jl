
using Documenter, Oracle

makedocs(
    sitename = "Oracle.jl",
    modules = [ Oracle ],
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "API Reference" => "api.md",
    ],
    checkdocs=:none,
)

deploydocs(
    repo = "github.com/felipenoris/Oracle.jl.git",
    target = "build",
)
