class Crinja::Node
  class Expression < Node
    property statement : Statement::Root

    def initialize(token : Crinja::Lexer::Token, @statement)
      super(token)
      @statement.parent_node = self
    end
  end
end
