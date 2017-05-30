class Crinja::Parser::TokenStream
  getter curr_pos

  @buffer : Array(Token)

  def initialize(lexer)
    initialize(lexer.tokenize)
  end

  def initialize(@buffer : Array(Token))
    @curr_pos = 0_u32
  end

  def rewind
    @curr_pos = 0_u32
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

    @buffer[pos]
  end

  def at(pos)
    at?(pos) || raise "Unexpected EOF"
  end

  def peek_token?(n = 1)
    at?(@curr_pos + n)
  end

  def peek_token(n = 1)
    at(@curr_pos + n)
  end
end
