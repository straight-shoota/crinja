require "logger"
require "../lexer/token_stream"

module Crinja::Parser
  alias TokenStream = Crinja::Lexer::TokenStream
  alias Token = Crinja::Lexer::Token
  alias Kind = Crinja::Lexer::Token::Kind

  class ParserError < Error
  end

  abstract class Base
    @logger = Logger.new(STDOUT)

    getter :logger, :token_stream
    delegate :next_token, :next_token?, :peek_token, :peek_token?, :current_token, to: token_stream
  end
end
