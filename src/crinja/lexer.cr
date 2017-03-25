module Crinja::Lexer
  class ParseException < Error
    getter token, char

    def initialize(message, @token : Token, char : Char)
      super "#{message} at #{token.line}:#{token.column} char=#{char}"
    end
  end
end

require "./lexer/*"
