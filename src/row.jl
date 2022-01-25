"""
    logger(args...)

A `Logger` object is callable.
Calling it will print a row of the logger.

## Inputs
**Required**
- Values corresponding to the keys used to create the logger.
"""
function (logger::Logger)(args...)
  if logger.verbosity > 0
    println(Printf.format(logger.fmt_row, args...))
  end
end
