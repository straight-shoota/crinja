module Crinja
  class Tag::Block < Tag
    name "block", "endblock"

    def interpret_output(env : Environment, tag_node : Node::Tag)
      if (name = expect_name(tag_node.varargs.first))
        env.blocks[name] << tag_node.children

        block = Node::BlockOutput.new(name)

        if tag_node.varargs.size > 1
          if expect_name(tag_node.varargs[1], "scoped")
            block.scope = env.context
          else
            raise TemplateSyntaxError.new(tag_node.varargs[1].token, "block tag with invalid modifier")
          end
        end

        block
      else
        raise TemplateSyntaxError.new(tag_node.varargs.first.token, "block tag expects a name")
      end
    end

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      raise "Unsupported operation"
    end
  end
end
