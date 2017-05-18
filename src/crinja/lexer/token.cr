class Crinja::Lexer::Token
  enum Kind
    INITIAL
    FIXED
    TAG_START
    TAG_END
    NOTE
    EXPR_START
    EXPR_END
    EOF

    # expression tokens
    NAME
    PIPE
    TEST
    OPERATOR

    # literal tokens
    STRING
    FLOAT
    INTEGER
    BOOL
    NONE

    LIST_START
    DICT_START
    LIST_SEPARATOR
    DICT_ASSIGN
    LIST_END
    DICT_END

    PARENTHESIS_START
    PARENTHESIS_END
    KW_ASSIGN

    TUPLE_START
    TUPLE_END
  end

  property kind : Kind

  property value : String

  property position : StreamPosition

  property trim_left = false, trim_right = false

  property whitespace_before : String?
  property whitespace_after : String?

  def initialize(@kind = Kind::INITIAL, @value = "", @position = StreamPosition.new)
  end

  def line
    position.line
  end

  def column
    position.column
  end

  def reset(pos)
    @value = ""
    @position = pos
    @whitespace_before = nil
    @whitespace_after = nil
  end

  def inspect(io : IO)
    io << kind
    preview = value
    preview = (value[0..5] + "..") if value.size > 7
    unless value.empty?
      io << ":"
      preview.dump(io)
    end
    io << "[" << line << ":" << column << "]"
    if whitespace_before
      io << " ws_before=\"" << whitespace_before.to_s << "\""
    end
    if whitespace_after
      io << " ws_after=\"" << whitespace_after.to_s << "\""
    end
  end

  def to_s(io : IO)
    inspect(io)
  end
end
