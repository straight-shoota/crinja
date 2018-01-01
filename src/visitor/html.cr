require "./source"

module Crinja
  class Visitor::HTML < Visitor::Source
    private def visit_content(token)
      case token.kind
      when Kind::TAG_START
        print_tag_start
      when Kind::EXPR_START
        print_expr_start
      end

      print_open_token_tag token

      super

      print_close_token_tag

      case token.kind
      when Kind::TAG_END
        print_tag_end
      when Kind::EXPR_END
        print_expr_end
      end
    end

    private def print_string_delimiter
      @io << "&quot;"
    end

    private def print_value(token)
      @io << SafeString.escape(token.value)
    end

    private def print_open_token_tag(token)
      @io << %Q(<span class="token token--#{token.kind.to_s.downcase}" title="#{token.kind.to_s} [#{token.line}:#{token.column}">)
    end

    private def print_close_token_tag
      @io << %Q(</span>)
    end

    private def print_tag_start
      @io << %(<span class="crinja__tag">)
    end

    private def print_tag_end
      @io << %(</span>)
    end

    private def print_expr_start
      @io << %(<span class="crinja__expr">)
    end

    private def print_expr_end
      @io << %(</span>)
    end
  end
end
