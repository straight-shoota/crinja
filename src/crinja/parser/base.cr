require "logger"
require "../lexer/token_stream"

module Crinja::Parser
  alias TokenStream = Crinja::Lexer::TokenStream
  alias Token = Crinja::Lexer::Token
  alias Kind = Crinja::Lexer::Token::Kind

  abstract class Base
    @logger = Logger.new(STDOUT)

    getter :logger, :token_stream
    delegate :next_token, :next_token?, :peek_token, :peek_token?, :current_token, to: token_stream

    def raise(message : String)
      raise(Crinja::TemplateSyntaxError.new(current_token, message))
    end

    def raise(error : Crinja::TemplateSyntaxError)
      error.token_stream = token_stream.dup

      ::raise(error)
    end
  end
end
