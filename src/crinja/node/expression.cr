class Crinja::Node
  class Expression < Node
    property statement : Statement

    def initialize(token : Crinja::Lexer::Token)
      super(token)

      @statement = Statement::Root.new(token)
    end

    def render(io : IO, env : Crinja::Environment)
      raise "Empty expression" if statement.nil?
      result = statement.not_nil!.evaluate(env)

      if env.context.autoescape?
        result = SafeString.escape(result)
      end

      io << result
    end

    def inspect_children(io : IO, indent = 0)
      statement.inspect(io, indent + 1)
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
