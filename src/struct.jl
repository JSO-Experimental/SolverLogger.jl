export Logger

"""
    Logger(
        :key1 => (name, fmt),
        :key2 => (name, fmt),
        …;
        kwargs...
    )

Creates a solver logger.

## Inputs

**Required:**
- Arbitrary number of pairs of `Symbol` (key) to `Tuple{String,String}` (name, formatting string).
  The _keys_ are currently not used, but could be in the future.
  The _names_ are used for `[header](@ref)s`.
  The _formatting string_ is a C printf type of formatting user for `[row](@ref)s`.

**Optional, by keyword:**
- `mode :: Symbol`: Define the logging operation. Valid options are
    - `print`: Prints to stdout using `println`.
    - (TODO) `save`: Prints to a file.
    - (TODO) `string`: Returns the string.
- `verbosity :: Int`: Verbosity level.
    - 0 means **silent**
    - Greater than 0 means **verbose**
    - (TODO) Different values

## Output

A `Logger` object.
"""
mutable struct Logger{PfH <: Printf.Format, PfR <: Printf.Format}
  keys::Vector{Symbol}
  names::Vector{String}
  formats::Vector{String}
  fmt_header::PfH
  fmt_row::PfR
  mode::Symbol
  verbosity::Int
end

function Logger(
  key_value_list::Pair{Symbol, Tuple{String, String}}...;
  mode::Symbol = :print,
  verbosity::Int = 0,
)
  n = length(key_value_list)
  keys = fill(:none, n)
  names = fill("", n)
  fmts = fill("", n)
  for (i, (k, v)) in enumerate(key_value_list)
    keys[i] = k
    names[i] = v[1]
    fmts[i] = v[2]
  end

  function fmt_to_str_fmt(x)
    m = match(r"%[^0-9]*([0-9]*)[.]*[0-9]*", x)
    if m === nothing || m.captures[1] == ""
      return "%s"
    end
    return "%" * m.captures[1] * "s"
  end

  pfh = Printf.Format("| " * join(fmt_to_str_fmt.(fmts), " | ") * " |")
  pfr = Printf.Format("| " * join(fmts, " | ") * " |")
  solver = Logger{typeof(pfh), typeof(pfr)}(
    keys,
    names,
    fmts,
    pfh,
    pfr,
    mode,
    verbosity,
  )

  return solver
end
