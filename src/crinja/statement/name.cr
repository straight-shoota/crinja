class Crinja::Statement
  class Name < Statement
    getter variable : Variable

    def initialize(token : Token = Token.new)
      super(token)
      @variable = Crinja::Variable.new(token.value)
    end

    def evaluate(env : Crinja::Environment) : Type
      env.resolve(variable)
    end

    def add_member(token)
      variable.add_part(token.value)
    end

    def name
      variable.to_s
    end
  end
end
