using Krylov, LinearAlgebra, Random

include("cg_new.jl")

macro wrappedallocs(expr)
  argnames = [gensym() for a in expr.args]
  quote
      function g($(argnames...))
          @allocated $(Expr(expr.head, argnames...))
      end
      $(Expr(:call, :g, [esc(a) for a in expr.args]...))
  end
end

function main()
  # First, compare Output
  Random.seed!(0)
  n = 5
  A = rand(n, n)
  A = A * A' + I
  b = A * ones(n)

  # Precompiling
  ksolver_cg = CgSolver(A, b)
  cg!(ksolver_cg, A, b)
  ksolver_cg_new = CgNewSolver(A, b)
  cg_new!(ksolver_cg_new, A, b)

  @info "Current CG"
  cg!(ksolver_cg, A, b)
  @info @wrappedallocs cg!(ksolver_cg, A, b)

  @info "New CG"
  cg_new!(ksolver_cg_new, A, b, verbose=0)
  @info @wrappedallocs cg_new!(ksolver_cg_new, A, b)

  # cg!(ksolver_cg, A, b, verbose=1)
  # cg_new!(ksolver_cg_new, A, b, verbose=1)
end

main()

nothing