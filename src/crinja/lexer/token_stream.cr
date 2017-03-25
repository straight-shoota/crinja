module Crinja::Lexer
  class TokenStream
    getter curr_pos

    @buffer : Array(Lexer::Token)

    def initialize(lexer : Lexer::Base)
      @buffer = lexer.tokenize
      @curr_pos = -1
    end

    def current_token?
      at?(@curr_pos)
    end

    def current_token
      at(@curr_pos)
    end

    def next_token?
      @curr_pos += 1
      token = at?(@curr_pos)
      token
    end

    def next_token
      @curr_pos += 1
      token = at(@curr_pos)
      token
    end

    def at?(pos)
      if pos >= @buffer.size || pos < 0
        return nil
      end

      token = @buffer[pos]

      if token.kind == Token::Kind::EOF
        return nil
      else
        token
      end
    end

    def at(pos)
      token = at?(pos)

      raise "Unexpected EOF" if token.nil?
      token
    end

    def peek_token?(n = 1)
      at?(@curr_pos + n)
    end

    def peek_token(n = 1)
      at(@curr_pos + n)
    end
  end
end
