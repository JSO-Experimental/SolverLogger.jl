using SolverLogger
using Documenter

DocMeta.setdocmeta!(SolverLogger, :DocTestSetup, :(using SolverLogger); recursive = true)

makedocs(;
  modules = [SolverLogger],
  doctest = true,
  linkcheck = false,
  strict = false,
  authors = "Abel Soares Siqueira <abel.s.siqueira@gmail.com> and contributors",
  repo = "https://github.com/JuliaSmoothOptimizers/SolverLogger.jl/blob/{commit}{path}#{line}",
  sitename = "SolverLogger.jl",
  format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", "false") == "true",
    canonical = "https://JuliaSmoothOptimizers.github.io/SolverLogger.jl",
    assets = ["assets/style.css"],
  ),
  pages = ["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
  repo = "github.com/JuliaSmoothOptimizers/SolverLogger.jl",
  push_preview = true,
  devbranch = "main",
)
