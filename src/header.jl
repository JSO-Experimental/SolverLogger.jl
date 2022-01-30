export header

"""
    header(logger)

Print the header of a [`Logger`](@ref).
"""
function header(logger::Logger)
  if logger.verbosity > 0
    println(Printf.format(logger.fmt_header, logger.names...))
  end
  nothing
end
