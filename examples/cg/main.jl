using Krylov, LinearAlgebra, Random

include("cg_new.jl")

# First, compare Output
Random.seed!(0)
n = 5
A = rand(n, n)
A = A * A' + I
b = A * ones(n)

@info "Current CG"
cg(A, b, verbose=0)
cg(A, b, verbose=1)

@info "New cG"
cg_new(A, b, verbose=0)
cg_new(A, b, verbose=1)

nothing