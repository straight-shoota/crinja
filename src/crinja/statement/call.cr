class Crinja::Statement
  class Call < Statement
    property target : Statement

    include ArgumentsList

    def initialize(token : Crinja::Lexer::Token, @target)
      super(token)
      target.parent = self
    end

    def evaluate(env : Crinja::Environment) : Type
      if (name_stmt = target).is_a?(Statement::Name) && !(root_node = self.root_node).nil? && root_node.template.macros.has_key?(name_stmt.name)
        # its a macro call
        callable = root_node.template.macros[name_stmt.name]
      else
        target_value = target.value(env)
        callable = target_value.raw
      end

      unless callable.is_a?(Crinja::Callable)
        raise "cannot call #{target_value.inspect}. Not a function"
      else
        arguments = if callable.responds_to?(:create_arguments)
                      callable.create_arguments
                    else
                      Crinja::Callable::Arguments.new
                    end

        varargs.each do |stmt|
          if stmt.is_a?(Statement::SplashOperator)
            stmt.operand.not_nil!.value(env).as_a.each do |arg|
              arguments.varargs << Any.new(arg)
            end
          else
            arguments.varargs << stmt.value(env)
          end
        end

        kwargs.each do |k, stmt|
          arguments.kwargs[k] = stmt.value(env)
        end

        callable.call(arguments)
      end
    end

    def inspect_children(io : IO, indent = 0)
      io << "\n" << "  " * indent << "<callable>"
      io << "\n" << "  " * (indent + 1)
      target.inspect(io, indent + 1)
      io << "\n" << "  " * indent << "</callable>"

      super(io, indent)
    end
  end
end
