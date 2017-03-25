class Crinja::Statement
  module ArgumentsList
    property varargs : Array(Statement) = [] of Statement
    property kwargs : Hash(String, Statement) = Hash(String, Statement).new

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

    def inspect_children(io : IO, indent = 0)
      unless varargs.empty?
        io << "\n" << "  " * indent << "<varargs>"
        varargs.each do |arg|
          io << "\n" << "  " * (indent + 1)
          arg.inspect(io, indent + 1)
        end
        io << "\n" << "  " * indent << "</varargs>"
      end
      unless kwargs.empty?
        kwargs.each do |kw, arg|
          io << "\n" << "  " * indent << "<kwarg name=\"" << kw << "\">"
          io << "\n" << "  " * (indent + 1)
          arg.inspect(io, indent + 1)
          io << "\n" << "  " * indent << "</kwarg>"
        end
      end
    end
  end
end
