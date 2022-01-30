using BenchmarkTools, Krylov, LinearAlgebra, Random, Statistics

include("cg_new.jl")

Random.seed!(0)
n = 1000
A = rand(n, n)
A = A * A' + I
b = A * ones(n)
ksolver_cg = CgSolver(A, b)
ksolver_cg_new = CgNewSolver(A, b)

function runall(ksolver, A, b, solver, args)
  solver(ksolver, A, b; args...)
end

benchmarks = []
options = [
  ("CG silent", cg!, ksolver_cg, Dict(:verbose => 0)),
  ("New CG silent", cg_new!, ksolver_cg_new, Dict(:verbose => 0)),
  ("CG verbose", cg!, ksolver_cg, Dict(:verbose => 1)),
  ("New CG verbose", cg_new!, ksolver_cg_new, Dict(:verbose => 1)),
]
for (name, solver, ksolver, args) in options
  bg = @benchmark for t = 1:10
    runall($ksolver, $A, $b, $solver, $args)
  end
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
