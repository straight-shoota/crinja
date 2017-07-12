require "./visitor"

# The source visitor transforms a template tree into Jinja source code.
class Crinja::Visitor::Source
  # :nodoc:
  alias Kind = Parser::Token::Kind

  def initialize(@io : IO)
  end

  def visit(template : Template)
    lexer = Parser::TemplateLexer.new(template.env.config, template.source)

    while token = lexer.next_token
      break if token.kind == Kind::EOF
      visit_token token
    end
  end

  def visit(tokens)
    tokens.each do |token|
      visit_token token
    end
  end

  private def visit_token(token : Parser::Token)
    print_whitespace_before token

    visit_content token

    print_whitespace_after token
  end

  private def visit_content(token)
    case token.kind
    when Kind::STRING
      print_string_delimiter
    end

    print_value token

    case token.kind
    when Kind::STRING
      print_string_delimiter
    end
  end

  private def print_string_delimiter
    @io << '"'
  end

  private def print_value(token)
    @io << token.value
  end

  private def print_whitespace_before(token)
    @io << token.whitespace_before
  end

  private def print_whitespace_after(token)
    @io << token.whitespace_after
  end
end
