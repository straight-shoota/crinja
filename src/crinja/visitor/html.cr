require "./source"

module Crinja
  class Visitor::HTML < Visitor::Source
    protected def print_token(token : Parser::Token?)
      unless token.nil?
        @io << token.whitespace_before
        open_token_tag token
        @io << SafeString.escape(token.value)
        close_token_tag
        @io << token.whitespace_after
      end
    end

    protected def open_token_tag(token)
      @io << %Q(<span class="token token--#{token.kind.to_s.downcase}" title="#{token.kind.to_s} [#{token.line}:#{token.column}">)
    end
    protected def close_token_tag
      @io << %Q(</span>)
    end
  end
end
