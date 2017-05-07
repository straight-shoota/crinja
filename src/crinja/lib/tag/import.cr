module Crinja
  class Tag::Import < Tag
    name "import"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      varargs = PeekIterator.new(tag_node.varargs)
      template_name = varargs.next.value(env).to_s

      env.context.import_path_stack << template_name

      if expect_name(varargs.peek?, "as")
        context_var = varargs.next.as(Statement::Name).name
      end

      template = env.get_template(template_name)

      if context_var.nil?
        template.render(env)
      else
        child = Environment.new(env)
        template.render(child)

        env.errors += child.errors

        child_bindings = child.context.session_bindings
        child.context.macros.each do |key, value|
          child_bindings[key] = value
        end

        env.context[context_var] = child_bindings
      end
    end
  end
end
