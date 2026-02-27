using Documenter
using DrawingDim

DocMeta.setdocmeta!(DrawingDim, :DocTestSetup, :(using DrawingDim); recursive=true)

makedocs(
    modules = [DrawingDim],
    sitename = "DrawingDim.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
    ),
    pages = [
        "Home" => "index.md",
        "Command Reference" => "commands.md",
        "Formatters" => "formatters.md",
        "Examples" => "examples.md",
        "Registration" => "registration.md",
    ],
)

deploydocs(
    repo = "github.com/tkrisnguyen/DrawingDim.git",
    devbranch = "main",
)
