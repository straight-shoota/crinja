class Crinja::Statement
  class Call < Statement
    property target : Statement

    include ArgumentsList

    def initialize(token, @target)
      super(token)
      target.parent = self
    end

    def evaluate(env : Environment) : Type
      if (name_stmt = target).is_a?(Statement::Name) && env.context.macros.has_key?(name_stmt.name)
        # its a macro call
        callable = env.context.macros[name_stmt.name]
      else
        target_value = target.value(env)
        callable = target_value.raw
      end

      unless callable.is_a?(Callable)
        raise "cannot call #{target_value.inspect}. Not a function"
      else
        arguments = if callable.responds_to?(:create_arguments)
                      callable.create_arguments(env)
                    else
                      Callable::Arguments.new(env)
                    end

        varargs.each do |stmt|
          if stmt.is_a?(SplashOperator)
            stmt.operand.not_nil!.value(env).as_a.each do |arg|
              arguments.varargs << Value.new(arg)
            end
          else
            arguments.varargs << stmt.value(env)
          end
        end

        kwargs.each do |k, stmt|
          arguments.kwargs[k] = stmt.value(env)
        end

        callable.call(arguments)
      end
    end

    def inspect_children(io : IO, indent = 0)
      io << "\n" << "  " * indent << "<callable>"
      io << "\n" << "  " * (indent + 1)
      target.inspect(io, indent + 1)
      io << "\n" << "  " * indent << "</callable>"

      super(io, indent)
    end
  end
end
