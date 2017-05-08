module Crinja::Lexer
  class TemplateLexer < Base
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

    @statement_lexer : StatementLexer?

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

    def statement_lexer
      @statement_lexer ||= StatementLexer.new(self.config, stream)
    end

    setter statement_lexer

    def next_token : Token
      @token.value = ""
      @token.position = stream.position

      case @stack.last
      when State::ROOT
        next_token_root
      when State::EXPRESSION
        check_for_end || (@token = statement_lexer.next_token)
      when State::TAG
        check_for_end || next_token_tag
      end

      @token.dup
    end

    def next_token_root
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

    def next_token_tag
      @token.position = stream.position

      if @token.kind == Kind::TAG_START
        # if last token is TAG_START, read tag name
        skip_whitespace
        consume_name
      else
        @token = statement_lexer.next_token
      end
    end

    def raise(message)
      ::raise(Crinja::TemplateSyntaxError.new(@token.dup, message))
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
          if check_for_end
            break
          end

          io << current_char
          next_char
        end
      end
    end

    # check if current scope closes
    def check_for_end
      trim_whitespace = false

      whitespace = 0
      while [' ', '\n', '\r', '\t'].includes?(peek_char(whitespace))
        whitespace += 1
      end

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

          if end_type != @stack.last.end_symbol
            raise "Terminated #{@stack.last} with '#{@token.value}'"
          end

          @token.kind = @stack.last.end_kind

          (whitespace + lookahead + 1).times { next_char }

          if trim_whitespace
            @token.trim_right = true
          end

          @stack.pop
          return true
        end
      when '\0'
        raise "Unterminated #{@stack.last.name}"
      end

      return false
    end
  end
end
