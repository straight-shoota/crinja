class Crinja::Statement
  class Filter < Statement
    property target : Statement

    include ArgumentsList

    def initialize(token : Crinja::Lexer::Token, @name_token : Crinja::Lexer::Token, @target)
      super(token)
      target.parent = self
    end

    def name
      @name_token.value
    end

    def evaluate(env : Crinja::Environment) : Type
      filter = resolve_filter(env)

      arguments = filter.create_arguments
      arguments.target = resolve_target(env)

      varargs.each do |stmt|
        arguments.varargs << stmt.value(env)
      end

      kwargs.each do |k, stmt|
        arguments.kwargs[k] = stmt.value(env)
      end

      filter.call(arguments)
    end

    def resolve_filter(env)
      env.context.filters[name]
    end

    def resolve_target(env)
      target.value(env)
    end

    def inspect_arguments(io : IO, indent = 0)
      io << " name=" << name
    end

    def inspect_children(io : IO, indent = 0)
      io << "\n" << "  " * indent << "<target>"
      io << "\n" << "  " * (indent + 1)
      target.inspect(io, indent + 1)
      io << "\n" << "  " * indent << "</target>"

      super(io, indent)
    end
  end
end
