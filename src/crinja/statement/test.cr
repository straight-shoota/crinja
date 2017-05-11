class Crinja::Statement
  class Test < Filter
    def resolve_filter(env)
      env.tests[name]
    end

    def resolve_target(env)
      target.value(env)
    end
  end
end
