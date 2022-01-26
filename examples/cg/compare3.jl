using BenchmarkTools, Krylov, LinearAlgebra, Random, SparseArrays, Statistics

include("cg_new.jl")

eye(n::Int) = sparse(1.0 * I, n, n)

function get_div_grad(n1 :: Int, n2 :: Int, n3 :: Int)

  # Divergence
  D1 = kron(eye(n3), kron(eye(n2), ddx(n1)))
  D2 = kron(eye(n3), kron(ddx(n2), eye(n1)))
  D3 = kron(ddx(n3), kron(eye(n2), eye(n1)))

  # DIV from faces to cell-centers
  Div = [D1 D2 D3]

  return Div * Div'
end

# 1D finite difference on staggered grid
function ddx(n :: Int)
  e = ones(n)
  return sparse([1:n; 1:n], [1:n; 2:n+1], [-e; e])
end

# Sparse Laplacian.
function sparse_laplacian(n :: Int=16)
  A = get_div_grad(n, n, n)
  b = ones(n^3)
  return A, b
end

A, b = sparse_laplacian()
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
  bg = @benchmark for t=1:10 runall($ksolver, $A, $b, $solver, $args) end
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
