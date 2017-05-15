class Crinja::Statement
  class Test < Filter
    property negative_test : Bool = false

    def resolve_filter(env)
      env.tests[name]
    end

    def evaluate(env : Environment) : Type
      value = super(env)
      if negative_test
        !value
      else
        !!value
      end
    end

    def resolve_target(env)
      target.value(env)
    end
  end
end
