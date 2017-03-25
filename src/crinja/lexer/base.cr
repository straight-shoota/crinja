module Crinja::Lexer
  abstract class Base
    alias Kind = Token::Kind

    SPECIAL_CONSTANTS = {
      "true"  => Kind::BOOL,
      "false" => Kind::BOOL,
      "none"  => Kind::NONE,
    }.tap do |h|
      # because `True` equaling to false causes confusion, it is possible to write these constants
      # in camel case. However lower case is preferred.
      h.each { |k, v| h[k.camelcase] = v }
    end

    getter config, stream

    def initialize(config : Crinja::Config, input : String)
      initialize(config, CharacterStream.new(input))
    end

    def initialize(@config : Crinja::Config, @stream : CharacterStream = CharacterStream.new)
      @token = Token.new
      @buffer = IO::Memory.new
    end

    delegate :next_char, :current_char, :peek_char, to: stream

    abstract def next_token : Token

    def tokenize
      tokens = [] of Token

      while t = next_token
        tokens << t
        break if t.kind == Kind::EOF
      end

      tokens
    end

    def consume_fixed
      @buffer.clear
      @buffer << current_char

      while true
        case char = next_char
        when '\0'
          break
        when Symbol::PREFIX
          case peek_char
          when Symbol::EXPR_START, Symbol::TAG, Symbol::NOTE
            break
          else
            @buffer << char
          end
        else
          @buffer << char
        end
      end

      @buffer.to_s
    end

    def consume_name
      @buffer.clear
      @buffer << current_char

      while true
        case char = next_char
        when .alphanumeric?, '_'
          @buffer << char
        else
          break
        end
      end

      @token.value = @buffer.to_s
      @token.kind = Kind::NAME

      if SPECIAL_CONSTANTS.has_key?(@token.value)
        @token.kind = SPECIAL_CONSTANTS[@token.value]
      end
    end

    def consume_string
      @buffer.clear
      escaped = false
      delimiter = current_char

      while true
        char = next_char

        if char == Char::ZERO
          raise "Unterminated string literal"
        end

        if escaped
          escaped = false

          case char
          when 'n'
            @buffer << '\n'
          when '"', '\''
            @buffer << char
          end
        else
          escaped = false
          case char
          when delimiter
            next_char
            break
          when Symbol::STRING_ESCAPE
            escaped = true
          else
            @buffer << char
          end
        end
      end

      @buffer.to_s
    end

    def consume_numeric
      @buffer.clear
      is_float = false

      @buffer << current_char

      while true
        case char = next_char
        when .number?
          @buffer << char
        when '.'
          @buffer << char
          raise "Invalid floating point number" if is_float
          is_float = true
        when ' ', Char::ZERO, Symbol::PARENTHESIS_END, Symbol::LIST_END, Symbol::DICT_END, Symbol::DICT_ASSIGN, Symbol::LIST_SEPARATOR
          break
        else
          raise "Invalid number. Found char: '#{char}'(#{char.ord}) at #{stream.position}"
        end
      end

      {is_float ? Kind::FLOAT : Kind::INTEGER, @buffer.to_s}
    end

    def skip_whitespace
      while true
        case current_char
        when ' ', '\t', '\n', '\r'
          next_char
        else
          break
        end
      end
    end

    def raise(msg)
      ::raise ParseException.new(msg, @token.dup, current_char)
    end
  end
end
