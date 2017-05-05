module Crinja::Lexer
  class StatementLexer < Base
    def next_token : Token
      @token.whitespace_before = skip_whitespace
      @token.position = stream.position

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
      when Symbol::OP_DIV, Symbol::OP_TIMES
        @token.kind = Kind::OPERATOR
        @token.value = current_char.to_s
        next_char

        if current_char == @token.value[0]
          @token.value = @token.value * 2
          next_char
        end
      when Symbol::OP_PLUS, Symbol::OP_MINUS
        if peek_char.number?
          @token.kind, @token.value = consume_numeric
        else
          @token.kind = Kind::OPERATOR
          @token.value = current_char.to_s
          next_char
        end
      when Symbol::OP_TILDE, Symbol::OP_MODULO, Symbol::MEMBER
        @token.kind = Kind::OPERATOR
        @token.value = current_char.to_s
        next_char
      when Symbol::COMP_EQ, Symbol::COMP_BANG, Symbol::COMP_GT, Symbol::COMP_LT
        @token.kind = Kind::OPERATOR

        peek = peek_char
        if peek == Symbol::COMP_EQ
          @token.value = current_char.to_s + peek
          next_char
        elsif current_char == Symbol::COMP_EQ
          @token.kind = Kind::KW_ASSIGN
          @token.value = Symbol::COMP_EQ.to_s
        elsif current_char == Symbol::COMP_BANG
          raise "Invalid comparator #{current_char}"
        else
          @token.value = current_char.to_s
        end
        next_char
      when .letter?, '_'
        consume_name

        if @token.value == "is"
          @token.kind = Kind::TEST
        end
      when Symbol::LIST_START
        @token.kind = Kind::LIST_START
        @token.value = current_char.to_s
        next_char
      when Symbol::DICT_START
        @token.kind = Kind::DICT_START
        @token.value = current_char.to_s
        next_char
      when Symbol::LIST_SEPARATOR
        @token.kind = Kind::LIST_SEPARATOR
        @token.value = current_char.to_s
        next_char
      when Symbol::DICT_ASSIGN
        @token.kind = Kind::DICT_ASSIGN
        @token.value = current_char.to_s
        next_char
      when Symbol::LIST_END
        @token.kind = Kind::LIST_END
        @token.value = current_char.to_s
        next_char
      when Symbol::DICT_END
        @token.kind = Kind::DICT_END
        @token.value = current_char.to_s
        next_char
      when Symbol::PARENTHESIS_START
        @token.kind = Kind::PARENTHESIS_START
        @token.value = current_char.to_s
        next_char
      when Symbol::PARENTHESIS_END
        @token.kind = Kind::PARENTHESIS_END
        @token.value = current_char.to_s
        next_char
      when Char::ZERO
        @token.kind = Kind::EOF
        @token.value = ""
      else
        raise "Not implemented expression value `#{current_char}`. #{@stream.inspect}"
      end

      @token.dup
    end
  end
end
