module Crinja::Lexer
  class CharacterStream
    @reader : Char::Reader
    @position = StreamPosition.new

    def initialize(string)
      @reader = Char::Reader.new(string)
    end

    delegate :current_char, to: @reader

    def peek_char(lookahead = 1)
      pos = @reader.pos + lookahead
      if @reader.string.size > pos
        @reader.string[pos]
      else
        Char::ZERO
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
    property line : Int32 = 0
    property column : Int32 = 0

    def ==(other : Tuple(Int32, Int32))
      {line, column} == other
    end
  end
end
