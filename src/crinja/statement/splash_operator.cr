class Crinja::Statement
  class SplashOperator < Statement
    include ParentStatement

    property operand : Statement?

    def <<(statement : Statement)
      raise "adding second operand to SplashOperator" unless operand.nil?
      self.operand = statement
    end

    def inspect_children(io : IO, indent = 0)
      io << "\n" << "  " * indent
      operand.try(&.inspect(io, indent))
    end

    def accepts_children?
      !operand.nil?
    end

    def evaluate(env : Environment) : Type
      raise "SplashOperator should never be evaluated directly"
    end
  end
end
