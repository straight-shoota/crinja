class Crinja::Statement
  class Function < Statement
    include ArgumentsList

    def name
      token.value
    end

    def evaluate(env : Crinja::Environment) : Type
      function = env.context.functions[name]

      arguments = function.create_arguments(env)

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

  # abstract class TestFunction < Function
  #   def raw_value(env : Crinja::Environment) : Type
  #     raise "context function must be applied with target"
  #   end

  #   def value(env : Crinja::Environment, target : Statement) : Any
  #     Any.new raw_value(env, target)
  #   end

  #   def raw_value(env : Crinja::Environment, target : Statement) : Type
  #     raise "NOT IMPLEMENTED"
  #     #filter = env.filters[name]

  #     target_value = target.value(env)
  #     return Any.new(nil) if target_value.nil?

  #     #filter.call(target_value, varargs, kwargs)
  #   end
  # end

end
