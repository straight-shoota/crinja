module Crinja::Parser
  class ExpressionLexer < BaseLexer
    @stack = [] of Kind

    def next_token : Token
      @token.reset(stream.position)
      @token.whitespace_before = skip_whitespace

      case current_char
      when Symbol::PIPE
        next_char
        @token.kind = Kind::PIPE
        @token.value = Symbol::PIPE.to_s
      when Symbol::STR_DELIMITER, Symbol::STR_DELIMITER_ALT
        @token.kind = Kind::STRING
        @token.value = consume_string
      when .number?
        @token.kind, @token.value = consume_numeric
      when '/', '*'
        @token.kind = Kind::OPERATOR
        @token.value = current_char.to_s
        next_char

        if current_char == @token.value[0]
          @token.value = @token.value * 2
          next_char
        end
      when '+', '-'
        if peek_char.number?
          @token.kind, @token.value = consume_numeric
        else
          @token.kind = Kind::OPERATOR
          @token.value = current_char.to_s
          next_char
        end
      when '~', '%'
        @token.kind = Kind::OPERATOR
        @token.value = current_char.to_s
        next_char
      when '.'
        @token.kind = Kind::POINT
        @token.value = Symbol::OP_MEMBER
        next_char
      when '!'
        if peek_char == '='
          @token.kind = Kind::OPERATOR
          @token.value = Symbol::OP_NOT_EQUAL
          next_char
        else
          raise "Invalid operator `!`"
        end
        next_char
      when '='
        if peek_char == '='
          @token.kind = Kind::OPERATOR
          @token.value = Symbol::OP_EQUAL
          next_char
        else
          @token.kind = Kind::KW_ASSIGN
          @token.value = Symbol::OP_ASSIGN
        end
        next_char
      when '>', '<'
        @token.kind = Kind::OPERATOR
        if peek_char == '='
          @token.value = current_char == '>' ? Symbol::OP_GREATER_EQUAL : Symbol::OP_LESS_EQUAL
          next_char
        else
          @token.value = current_char == '>' ? Symbol::OP_GREATER : Symbol::OP_LESS
        end
        next_char
      when .letter?, '_'
        consume_name

        case @token.value
        when Symbol::TEST
          @token.kind = Kind::TEST
        when Symbol::OP_NOT, Symbol::OP_AND, Symbol::OP_OR
          @token.kind = Kind::OPERATOR
        end
      when Symbol::LEFT_BRACKET
        @token.kind = Kind::LEFT_BRACKET
        @token.value = current_char.to_s
        @stack << Kind::RIGHT_BRACKET
        next_char
      when Symbol::LEFT_CURLY
        @token.kind = Kind::LEFT_CURLY
        @token.value = current_char.to_s
        @stack << Kind::RIGHT_CURLY
        next_char
      when Symbol::COMMA
        @token.kind = Kind::COMMA
        @token.value = current_char.to_s
        next_char
      when Symbol::DICT_ASSIGN
        @token.kind = Kind::DICT_ASSIGN
        @token.value = current_char.to_s
        next_char
      when Symbol::RIGHT_BRACKET
        @token.kind = Kind::RIGHT_BRACKET
        @token.value = current_char.to_s
        pop_stack
        next_char
      when Symbol::RIGHT_CURLY
        @token.kind = Kind::RIGHT_CURLY
        @token.value = current_char.to_s
        pop_stack
        next_char
      when Symbol::LEFT_PAREN
        @token.kind = Kind::LEFT_PAREN
        @token.value = current_char.to_s
        @stack << Kind::RIGHT_PAREN
        next_char
      when Symbol::RIGHT_PAREN
        @token.kind = Kind::RIGHT_PAREN
        @token.value = current_char.to_s

        pop_stack
        next_char
      when Char::ZERO
        @token.kind = Kind::EOF
        @token.value = ""
      else
        raise "Not implemented expression value `#{current_char}`. #{@stream.inspect}"
      end

      @token.dup
    end

    def pop_stack
      if stack_closed?
        if @token.kind == Kind::EXPR_END
          return
        else
          raise "Not expecting closing symbol #{@token.kind}"
        end
      end

      if @stack.last == @token.kind
        @stack.pop
      else
        raise "Expecting #{@stack.last}, instead found #{@token.kind}"
      end
    end

    # We need to keep track of current stack to be able to distinguish if "}}}" means
    # `[RIGHT_CURLY, EXPR_END]` or [EXPR_END, FIXED("}")]`
    def stack_closed?
      @stack.empty?
    end
  end
end
