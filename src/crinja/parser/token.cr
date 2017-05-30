class Crinja::Parser::Token
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
    IDENTIFIER
    PIPE
    TEST
    OPERATOR

    # literal tokens
    STRING
    FLOAT
    INTEGER
    BOOL
    NONE

    LEFT_BRACKET
    LEFT_CURLY
    DICT_ASSIGN
    RIGHT_BRACKET
    RIGHT_CURLY

    LEFT_PAREN
    RIGHT_PAREN
    KW_ASSIGN

    POINT
    COMMA

    TUPLE_START
    TUPLE_END
  end

  property kind : Kind

  property value : String

  property location : StreamPosition

  property trim_left = false, trim_right = false

  property whitespace_before : String?
  property whitespace_after : String?

  def initialize(@kind = Kind::INITIAL, @value = "", @location = StreamPosition.new)
  end

  def location_start
    location + (whitespace_before || "")
  end

  def location_end
    location_start + value
  end

  def line
    location.line
  end

  def column
    location.column
  end

  def reset(pos)
    @value = ""
    @location = pos
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
