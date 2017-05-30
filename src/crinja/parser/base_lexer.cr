module Crinja::Parser
  abstract class BaseLexer
    # :nodoc:
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

      @stream.rewind

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

    def consume_name(with_special_constants = true)
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
      @token.kind = Kind::IDENTIFIER

      if with_special_constants && SPECIAL_CONSTANTS.has_key?(@token.value)
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
        when ' ', '\n', '\t', '\r', Char::ZERO, Symbol::RIGHT_PAREN, Symbol::RIGHT_BRACKET, Symbol::RIGHT_CURLY, Symbol::DICT_ASSIGN, Symbol::COMMA, Symbol::PIPE,
             '~', '+', '-', '*', '/', '%', '=', '>', '<', '!'
          break
        else
          raise "Invalid number. Found char: '#{char}'(#{char.ord}) at #{stream.position}"
        end
      end

      {is_float ? Kind::FLOAT : Kind::INTEGER, @buffer.to_s}
    end

    def skip_whitespace
      whitespace = String.build do |io|
        while true
          if Symbol::WHITESPACE.includes?(current_char)
            skipped_whitespace = true
            io << current_char
            next_char
          else
            break
          end
        end
      end
      if whitespace.empty?
        nil
      else
        whitespace
      end
    end

    def raise(message)
      ::raise(Crinja::TemplateSyntaxError.new(@token.dup, message))
    end
  end
end
