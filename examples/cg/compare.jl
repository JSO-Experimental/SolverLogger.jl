using BenchmarkTools, Krylov, LinearAlgebra, Random, Statistics

include("cg_new.jl")

function runall(solver, args)
  Random.seed!(0)
  for n = [10, 50, 100, 500]
    for t = 1:10
      A = rand(n, n)
      A = A * A' + I
      b = A * ones(n)
      solver(A, b; args...)
    end
  end
end

benchmarks = []
options = [
  ("CG silent", cg, Dict(:verbose => 0)),
  ("New CG silent", cg_new, Dict(:verbose => 0)),
  ("CG verbose", cg, Dict(:verbose => 1)),
  ("New CG verbose", cg_new, Dict(:verbose => 1)),
]
for (name, solver, args) in options
  bg = @benchmark runall($solver, $args)
  push!(benchmarks, bg)
end

@info "Complete histogram"
for i = 1:length(benchmarks)
  @info options[i][1]
  display(benchmarks[i])
end

@info "Summary"
for i = 1:length(benchmarks)
  t = benchmarks[i].times
  @info options[i][1] mean(t) std(t)
end