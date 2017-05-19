class Crinja::Statement
  module ArgumentsList
    property varargs : Array(Statement) = [] of Statement
    property kwargs : Hash(String, Statement) = Hash(String, Statement).new

    # This property determines if the function call was followed by parenthesis.
    property has_parenthesis : Bool = false

    include ParentStatement

    def <<(child : Statement)
      if @await_keyword_argument.nil?
        raise TemplateSyntaxError.new(child.token, "varargs must preceed all kwargs") unless kwargs.empty?

        varargs << child
      else
        kwargs[@await_keyword_argument.not_nil!] = child
        @await_keyword_argument = nil
      end
      child.parent = self
    end

    def await_keyword_argument(keyword : String)
      @await_keyword_argument = keyword
    end

    def accepts_children?
      true
    end

  end
end
