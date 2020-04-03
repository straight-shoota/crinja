require "log"
require "./token_stream"

module Crinja::Parser::ParserHelper
  # :nodoc:
  alias Kind = Parser::Token::Kind

  getter :token_stream
  delegate :next_token, :next_token?, :peek_token, :peek_token?, :current_token, to: token_stream

  def initialize(lexer : BaseLexer)
    initialize(TokenStream.new(lexer))
  end

  def initialize(@token_stream : TokenStream)
  end

  def raise(message : String)
    ::raise(Crinja::TemplateSyntaxError.new(current_token, message))
  end

  # :nodoc:
  private def expect(type : Token::Kind)
    unless current_token.kind == type
      unexpected_token type
    end

    next_token
  end

  # :nodoc:
  private def expect(type : Token::Kind, value : String)
    unless current_token.kind == type && current_token.value == value
      unexpected_token type, value
    end

    next_token
  end

  # :nodoc:
  private def unexpected_token(expected : Token::Kind? = nil, value : String? = nil)
    if current_token.kind != Token::Kind::EOF
      if expected && value
        error_message = "Expected #{value}, got #{current_token.kind}"
      elsif expected
        error_message = "Expected #{expected}, got #{current_token.kind}"
      else
        error_message = "Unexpected #{current_token.kind}"
      end
    else
      if value
        error_message = "Unexpected end of file, expected #{value}"
      elsif expected
        error_message = "Unexpected end of file, expected #{expected}"
      else
        error_message = "Unexpected end of file"
      end
    end

    raise TemplateSyntaxError.new(current_token, error_message)
  end

  # :nodoc:
  private def assert_token(type : Token::Kind)
    unless current_token.kind == type
      unexpected_token type
    end

    yield
  end

  # :nodoc:
  private def assert_token(type : Token::Kind, value : String)
    unless current_token.kind == type && current_token.value == value
      unexpected_token type, value
    end

    yield
  end

  # :nodoc:
  private def if_token(type : Kind)
    yield if current_token.kind == type
  end

  # :nodoc:
  private def if_token(type : Kind, value : String)
    yield if current_token.kind == type && current_token.value == value
  end

  def close
    if next_token? && current_token.kind != Kind::EOF
      raise TemplateSyntaxError.new(current_token, "Did not expect any more tokens, found: #{current_token}")
    end
  end
end
