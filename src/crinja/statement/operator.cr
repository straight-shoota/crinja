class Crinja::Statement
  class Operator < Statement
    include ParentStatement

    property operands : Array(Statement) = [] of Statement
    property operator : Crinja::Operator

    alias Token = Crinja::Lexer::Token

    def initialize(token, @operator)
      super(token)
    end

    def name
      token.value
    end

    delegate :unary?, :binary?, :ternary?, :num_operands, to: :operator

    def <<(statement : Statement)
      raise "adding #{operands.size + 1}. child to #{operator}" unless num_operands > operands.size
      add_operand(statement)
    end

    def add_operand(statement : Statement)
      operands << statement
      statement.parent = self
    end

    def accepts_children?
      operands.size < num_operands
    end
  end
end
