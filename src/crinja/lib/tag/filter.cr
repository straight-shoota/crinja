module Crinja
  class Tag::Filter < Tag
    name "filter", "endfilter"

    def interpret_output(env : Crinja::Environment, tag_node : Node::Tag)
      filter_stmt = tag_node.varargs.first
      varargs : Array(Any) = [] of Any
      kwargs : Hash(String, Any) = Hash(String, Any).new

      if filter_stmt.is_a?(Statement::Name)
        filter_name = filter_stmt.name
      elsif filter_stmt.is_a?(Statement::Call)
        filter_name = filter_stmt.target.as(Statement::Name).name
      else
        raise TemplateSyntaxError.new(filter_stmt.token, "Argument for filter tag must be a filter call")
      end

      filter = env.context.filters[filter_name]

      arguments = if filter.responds_to?(:create_arguments)
                    filter.create_arguments(env)
                  else
                    Crinja::Callable::Arguments.new(env)
                  end

      # TODO: Wrap in OutputNode or find a better way
      arguments.target = Any.new(render_children(env, tag_node).value)

      if filter_stmt.is_a?(Statement::Call)
        filter_stmt.varargs.each do |stmt|
          if stmt.is_a?(Statement::SplashOperator)
            stmt.operand.not_nil!.value(env).as_a.each do |arg|
              arguments.varargs << Any.new(arg)
            end
          else
            arguments.varargs << stmt.value(env)
          end
        end

        filter_stmt.kwargs.each do |k, stmt|
          arguments.kwargs[k] = stmt.value(env)
        end
      end

      Node::RenderedOutput.new(filter.call(arguments).to_s)
    end

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      raise "Unsupported operation"
    end
  end
end
