class Crinja::Node
  class Root < Node
    property template : Template

    def initialize(@template)
      super(Crinja::Lexer::Token.new)
    end

    def render(io : IO, env : Crinja::Environment)
      render_children(io, env)
    end

    def root
      self
    end
  end
end
