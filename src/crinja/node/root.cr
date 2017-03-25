class Crinja::Node
  class Root < Node
    property template : Template

    def initialize(@template)
      super(Crinja::Lexer::Token.new)
    end

    def render(env : Crinja::Environment)
      raise "Unsupported render for root node"
    end

    def root
      self
    end
  end
end
