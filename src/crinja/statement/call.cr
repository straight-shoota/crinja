class Crinja::Statement
  class Call < Statement
    property target : Statement

    include ArgumentsList

    def initialize(token, @target)
      super(token)
      target.parent = self
    end

    def evaluate(env : Environment) : Type
      if (name_stmt = target).is_a?(Statement::Name)
        calling = name_stmt.variable
      else
        calling = target.value(env)
      end

      env.execute_call(calling) do |arguments|
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
      end
    end
  end
end
