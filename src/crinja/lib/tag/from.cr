module Crinja
  class Tag::From < Tag
    name "from"

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      imports = Hash(String, String).new

      varargs = Util::PeekIterator.new(tag_node.varargs)
      template_name = varargs.next.accept(env.evaluator).to_s
      expect_name(varargs.next, "import")
      with_context = false

      while arg = varargs.next?
        from_name = expect_name(arg) || raise TemplateSyntaxError.new(arg.token, "Expected name token")
        import_name = from_name

        if expect_name(varargs.peek?, "context")
          if from_name == "with"
            with_context = true
            break
          elsif from_name == "without"
            with_context = false
            break
          end
        end

        if expect_name(varargs.peek?, "as")
          varargs.next
          import_name = varargs.next.accept(env.evaluator).to_s
        end

        imports[from_name] = import_name
      end

      template = env.get_template(template_name)

      child = if with_context
                Environment.new(env)
              else
                Environment.new
              end

      template.render(child)

      env.errors += child.errors

      imports.each do |from_name, import_name|
        if template.macros.has_key?(from_name)
          env.context.macros[import_name] = template.macros[from_name]
        elsif child.context.has_key?(from_name)
          env.context[import_name] = child.context[from_name]
        else
          raise RuntimeError.new("Unknown import #{from_name} in #{template}")
        end
      end
    end
  end
end
