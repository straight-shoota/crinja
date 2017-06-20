class Crinja::Parser::TemplateLexer < Crinja::Parser::BaseLexer
  struct State
    ROOT       = State.new "root", Char::ZERO, Kind::EOF
    EXPRESSION = State.new "expression", Symbol::EXPR_END, Kind::EXPR_END
    TAG        = State.new "tag", Symbol::TAG, Kind::TAG_END
    NOTE       = State.new "note", Symbol::NOTE, Kind::NOTE

    getter end_symbol, end_kind, name

    def initialize(@name : String, @end_symbol : Char, @end_kind : Kind)
    end

    def to_s(io : IO)
      io << "<State:#{name}>"
    end
  end

  @expression_lexer : ExpressionLexer?
  @is_raw = false

  def initialize(config : Crinja::Config, input : String)
    initialize(config, CharacterStream.new(input))
  end

  def initialize(config : Crinja::Config, input : String)
    initialize(config, CharacterStream.new(input))
  end

  def initialize(config : Crinja::Config, stream : CharacterStream)
    super(config, stream)

    @stack = [State::ROOT]
    @state = State::ROOT
  end

  def expression_lexer
    @expression_lexer ||= ExpressionLexer.new(self.config, stream)
  end

  setter expression_lexer

  def next_token : Token
    @token.reset(stream.position)

    case @stack.last
    when State::ROOT
      next_token_root
    when State::EXPRESSION
      if expression_lexer.stack_closed? && check_for_end(@stack.last)
        @stack.pop
      else
        @token = expression_lexer.next_token
      end
    when State::TAG
      if check_for_end(@stack.last)
        @stack.pop
      else
        next_token_tag
      end
    end

    @token.dup
  end

  def next_token_root
    if @is_raw
      return next_token_raw
    end

    case current_char
    when Char::ZERO
      @token.kind = Kind::EOF
    when Symbol::PREFIX
      peek = peek_char
      case peek
      when Symbol::TAG
        @token.kind = Kind::TAG_START
        @stack << State::TAG
      when Symbol::EXPR_START
        @token.kind = Kind::EXPR_START
        @stack << State::EXPRESSION
      when Symbol::NOTE
        @token.kind = Kind::NOTE
        @stack << State::NOTE
        @token.value = consume_note
        return
      else
        @token.kind = Kind::FIXED
        @token.value = consume_fixed
        return
      end

      @token.value = current_char.to_s + next_char
      next_char

      if current_char == Symbol::TRIM_WHITESPACE
        @token.value += current_char
        @token.trim_left = true
        next_char
      end
    else
      @token.kind = Kind::FIXED
      @token.value = consume_fixed
      return
    end
  end

  def next_token_raw
    @token.value = consume_raw
    @token.kind = Kind::FIXED
    @is_raw = false
  end

  def consume_raw
    @buffer.clear

    while true
      char = current_char
      break if char == Char::ZERO
      if char == Symbol::PREFIX
        if peek_char == Symbol::TAG
          if peek_string?(Symbol::RAW_END, 2)
            break
          end
        end
      end

      @buffer << char
      next_char
    end

    @buffer.to_s
  end

  def peek_string?(string, offset = 1)
    offset = peek_for_whitespace_offset(offset)
    string.chars.each_with_index(offset) do |c, i|
      return false if c != peek_char(i)
    end
    true
  end

  def next_token_tag
    @token.location = stream.position

    if @token.kind == Kind::TAG_START
      # if last token is TAG_START, read tag name
      @token.whitespace_before = skip_whitespace
      consume_name(with_special_constants: false)

      if @token.value == Symbol::RAW_START
        @is_raw = true
      elsif @token.value == Symbol::RAW_END
        @is_raw = false
      end
    else
      @token = expression_lexer.next_token
    end
  end

  def consume_note
    String.build do |io|
      io << current_char # = '{'
      io << next_char    # = '#'
      next_char

      if current_char == Symbol::TRIM_WHITESPACE
        @token.trim_left = true
      end

      while current_char
        if check_for_end(@stack.last)
          @stack.pop
          break
        end

        io << current_char
        next_char
      end
    end
  end

  def peek_for_whitespace_offset(offset = 1)
    while Symbol::WHITESPACE.includes?(peek_char(offset))
      offset += 1
    end
    offset
  end

  # check if current scope closes
  def check_for_end(current_scope)
    trim_whitespace = false

    whitespace = peek_for_whitespace_offset(0)

    lookahead = 0
    end_type = peek_char(whitespace + lookahead)
    lookahead += 1

    if end_type == Symbol::TRIM_WHITESPACE
      trim_whitespace = true
      end_type = peek_char(whitespace + lookahead)
      lookahead += 1
    end

    case end_type
    when Symbol::EXPR_END, Symbol::TAG, Symbol::NOTE
      if Symbol::POSTFIX == peek_char(whitespace + lookahead)
        @token.value = String.build do |io|
          io << Symbol::TRIM_WHITESPACE if trim_whitespace
          io << end_type << Symbol::POSTFIX
        end

        if end_type != current_scope.end_symbol
          raise "Terminated #{@stack.last} with '#{@token.value}'"
        end

        @token.kind = current_scope.end_kind

        @token.whitespace_before = String.build do |io|
          whitespace.times { io << current_char; next_char }
        end

        (lookahead + 1).times { next_char }

        if trim_whitespace
          @token.trim_right = true
        end

        return true
      end
    when Char::ZERO
      raise "Unterminated #{@stack.last.name}"
    end

    return false
  end
end
