Crinja.function(:debug) do
  STDERR.puts arguments.varargs.pretty_inspect
  STDERR.puts arguments.kwargs.pretty_inspect unless arguments.kwargs.empty?
end
