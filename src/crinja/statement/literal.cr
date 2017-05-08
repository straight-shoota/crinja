class Crinja::Statement
  class Literal < Statement
    alias Kind = Crinja::Lexer::Token::Kind

    def evaluate(env : Crinja::Environment) : Type
      case token.kind
      when Kind::INTEGER
        token.value.to_i64
      when Kind::FLOAT
        token.value.to_f
      when Kind::STRING
        token.value.to_s
      when Kind::BOOL
        token.value.downcase == "true"
      when Kind::NONE
        nil
      else
        raise "Unrecognized literal token value #{token.kind}"
      end
    end

    def inspect_children(io : IO, indent = 0)
      io << "\n" << "  " * indent
      token.value.to_s(io)
    end
  end
end
