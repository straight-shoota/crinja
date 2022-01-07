module Crinja::Parser
  class CharacterStream
    @reader : Char::Reader
    @position = StreamPosition.new

    def initialize(string)
      @reader = Char::Reader.new(string)
    end

    delegate :current_char, to: @reader

    def rewind
      @reader.pos = 0
    end

    def peek_char(lookahead = 1)
      if lookahead == 0
        @reader.current_char
      elsif lookahead == 1
        @reader.peek_next_char
      elsif lookahead > 1
        original_pos = @reader.pos
        (lookahead - 1).times do
          @reader.next_char
        end
        char = @reader.peek_next_char
        @reader.pos = original_pos
        char
      else
        raise Arguments::Error.new("lookahead must be >= 0, was #{lookahead}")
      end
    end

    def next_char
      char = @reader.next_char

      @position.column += 1

      if char == '\n'
        @position.column = 0
        @position.line += 1
      end

      char
    end

    def position
      @position.pos = @reader.pos
      @position.dup
    end
  end

  struct StreamPosition
    property pos : Int32 = 0
    property line : Int32 = 1
    property column : Int32 = 1

    def ==(other : ::Tuple(Int, Int))
      {line, column} == other
    end

    def ==(other : ::Tuple(Int, Int, Int))
      {line, column, pos} == other
    end

    def +(string : String)
      self.pos += string.size
      lines = string.split('\n')
      self.line += lines.size - 1
      if lines.size > 1
        self.column = lines.last.size
      else
        self.column += string.size
      end
      self
    end

    def to_s(io)
      io << line << ":" << column
    end

    def inspect(io)
      to_s(io)
      io << "@" << pos
    end
  end
end
