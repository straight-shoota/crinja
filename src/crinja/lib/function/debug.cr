Crinja.function(:debug) do
  String.build do |io|
    if arguments.varargs.empty? && arguments.kwargs.empty?
      io.puts "--- DEBUG context ----"
      PrettyPrint.format(env.context, io, 79)
      io.puts
    else
      io.puts "--- DEBUG arguments --"
      PrettyPrint.format(arguments.varargs, io, 79)
      io.puts
      unless arguments.kwargs.empty?
        PrettyPrint.format(arguments.kwargs, io, 79)
        io.puts
      end
    end
    io << "----------------------"
  end
end
