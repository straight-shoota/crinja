class Crinja::Statement
  class Function < Statement
    include ArgumentsList

    def name
      token.value
    end

    def evaluate(env : Environment) : Type
      function = env.functions[name]

      arguments = Arguments.new(env)

      varargs.each do |stmt|
        arguments.varargs << stmt.value(env)
      end

      kwargs.each do |k, stmt|
        arguments.kwargs[k] = stmt.value(env)
      end

      function.call(arguments)
    end

    def inspect_arguments(io : IO, indent = 0)
      io << " name=" << name
    end
  end
end
