class Crinja::Node
  class Expression < Node
    property statement : Statement

    def initialize(token : Crinja::Lexer::Token)
      super(token)

      @statement = Statement::Root.new(token)
    end

    def <<(node : Statement)
      if statement.is_a?(Statement::Root)
        statement = node
      else
        raise "Unrecognized additional statement"
      end
    end
  end
end
