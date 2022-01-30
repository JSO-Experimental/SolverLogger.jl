using Krylov: @kaxpby!, @kdot, @kaxpy!, ktypeof, allocate_if, reset!, SimpleStats, krylov_dot, krylov_axpy!, krylov_axpby!
using Printf
using SolverLogger

mutable struct CgNewSolver{T,S,L <: Logger} <: KrylovSolver{T,S}
  Δx    :: S
  x     :: S
  r     :: S
  p     :: S
  Ap    :: S
  z     :: S
  stats :: SimpleStats{T}
  logger :: L

  function CgNewSolver(n, m, S)
    T  = eltype(S)
    Δx = S(undef, 0)
    x  = S(undef, n)
    r  = S(undef, n)
    p  = S(undef, n)
    Ap = S(undef, n)
    z  = S(undef, 0)
    stats = SimpleStats(0, false, false, T[], T[], T[], "unknown")
    logger = Logger(
      :iter => ("k", "%5d"),
      :rNorm => ("‖r‖", "%7.1e"),
      :pAp => ("pAp", "%8.1e"),
      :α => ("α", "%8.1e"),
      :β => ("β", "%8.1e"),
      mode = :print,
    )
    solver = new{T,S,typeof(logger)}(Δx, x, r, p, Ap, z, stats, logger)
    return solver
  end

  function CgNewSolver(A, b)
    n, m = size(A)
    S = ktypeof(b)
    CgNewSolver(n, m, S)
  end
end

function cg_new(A, b :: AbstractVector{T}; kwargs...) where T <: AbstractFloat
  solver = CgNewSolver(A, b)
  cg_new!(solver, A, b; kwargs...)
  return (solver.x, solver.stats)
end

function cg_new!(solver :: CgNewSolver{T,S,L}, A, b :: AbstractVector{T};
             M=I, atol :: T=√eps(T), rtol :: T=√eps(T), restart :: Bool=false,
             itmax :: Int=0, radius :: T=zero(T), linesearch :: Bool=false,
             logger :: Logger = solver.logger,
             verbose :: Int=0, history :: Bool=false) where {T <: AbstractFloat, S <: DenseVector{T}, L <: Logger}

  linesearch && (radius > 0) && error("`linesearch` set to `true` but trust-region radius > 0")

  n, m = size(A)
  m == n || error("System must be square")
  length(b) == n || error("Inconsistent problem size")
  (verbose > 0) && @printf("CG: system of %d equations in %d variables\n", n, n)

  # Tests M = Iₙ
  MisI = (M === I)

  # Check type consistency
  eltype(A) == T || error("eltype(A) ≠ $T")
  ktypeof(b) == S || error("ktypeof(b) ≠ $S")

  # Set up workspace.
  allocate_if(!MisI  , solver, :z , S, n)
  allocate_if(restart, solver, :Δx, S, n)
  Δx, x, r, p, Ap, stats = solver.Δx, solver.x, solver.r, solver.p, solver.Ap, solver.stats
  rNorms = stats.residuals
  reset!(stats)
  z = MisI ? r : solver.z

  restart && (Δx .= x)
  x .= zero(T)
  if restart
    mul!(r, A, Δx)
    @kaxpby!(n, one(T), b, -one(T), r)
  else
    r .= b
  end
  MisI || mul!(z, M, r)
  p .= z
  γ = @kdot(n, r, z)
  rNorm = sqrt(γ)
  history && push!(rNorms, rNorm)
  if γ == 0
    stats.niter = 0
    stats.solved, stats.inconsistent = true, false
    stats.status = "x = 0 is a zero-residual solution"
    return solver
  end

  iter = 0
  itmax == 0 && (itmax = 2 * n)

  pAp = zero(T)
  pNorm² = γ
  ε = atol + rtol * rNorm

  # logger.verbosity = verbose
  # header(logger)

  solved = rNorm ≤ ε
  tired = iter ≥ itmax
  inconsistent = false
  on_boundary = false
  zero_curvature = false

  status = "unknown"

  while !(solved || tired || zero_curvature)
    mul!(Ap, A, p)
    pAp = @kdot(n, p, Ap)
    if (pAp ≤ eps(T) * pNorm²) && (radius == 0)
      if abs(pAp) ≤ eps(T) * pNorm²
        zero_curvature = true
        inconsistent = !linesearch
      end
      if linesearch
        iter == 0 && (x .= b)
        solved = true
      end
    end
    (zero_curvature || solved) && continue

    α = γ / pAp

    # Compute step size to boundary if applicable.
    σ = radius > 0 ? maximum(to_boundary(x, p, radius, dNorm2=pNorm²)) : α

    Krylov.display(iter, verbose) && row(logger, iter, rNorm, pAp, α, σ)

    # Move along p from x to the boundary if either
    # the next step leads outside the trust region or
    # we have nonpositive curvature.
    if (radius > 0) && ((pAp ≤ 0) || (α > σ))
      α = σ
      on_boundary = true
    end

    @kaxpy!(n,  α,  p, x)
    @kaxpy!(n, -α, Ap, r)
    MisI || mul!(z, M, r)
    γ_next = @kdot(n, r, z)
    rNorm = sqrt(γ_next)
    history && push!(rNorms, rNorm)

    solved = (rNorm ≤ ε) || on_boundary

    if !solved
      β = γ_next / γ
      pNorm² = γ_next + β^2 * pNorm²
      γ = γ_next
      @kaxpby!(n, one(T), z, β, p)
    end

    iter = iter + 1
    tired = iter ≥ itmax
  end
  (verbose > 0) && @printf("\n")

  solved && on_boundary && (status = "on trust-region boundary")
  solved && linesearch && (pAp ≤ 0) && (status = "nonpositive curvature detected")
  solved && (status == "unknown") && (status = "solution good enough given atol and rtol")
  zero_curvature && (status = "zero curvature detected")
  tired && (status = "maximum number of iterations exceeded")

  # Update x
  restart && @kaxpy!(n, one(T), Δx, x)

  # Update stats
  stats.niter = iter
  stats.solved = solved
  stats.inconsistent = inconsistent
  stats.status = status
  return solver
end
