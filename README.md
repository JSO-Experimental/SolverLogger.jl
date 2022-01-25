# SolverLogger

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaSmoothOptimizers.github.io/SolverLogger.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaSmoothOptimizers.github.io/SolverLogger.jl/dev)
[![Build Status](https://github.com/JuliaSmoothOptimizers/SolverLogger.jl/workflows/CI/badge.svg)](https://github.com/JuliaSmoothOptimizers/SolverLogger.jl/actions)
[![Build Status](https://api.cirrus-ci.com/github/JuliaSmoothOptimizers/SolverLogger.jl.svg)](https://cirrus-ci.com/github/JuliaSmoothOptimizers/SolverLogger.jl)
[![Coverage](https://codecov.io/gh/JuliaSmoothOptimizers/SolverLogger.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaSmoothOptimizers/SolverLogger.jl)

This is a logger for solvers, as the name implies.

## Basic usage

```
julia> logger = Logger(:iter => ("Iter", "%4d"), :fx => ("f(x)", "%8.1e"), verbosity=1)
...
julia> header(logger)
| Iter |     f(x) |
julia> logger(45, sqrt(2))
|   45 |  1.4e+00 |
```