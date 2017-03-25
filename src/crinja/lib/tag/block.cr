module Crinja
  class Tag::Block < Tag
    name "block", "endblock"

    def interpret_output(env : Environment, tag_node : Node::Tag)
      if (name = expect_name(tag_node.varargs.first))
        env.blocks[name] << tag_node.children

        Node::BlockOutput.new(name)
      else
        raise TemplateSyntaxError.new(tag_node.varargs.first.token, "block tag expects a name")
      end
    end

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      raise "Unsupported operation"
    end
  end
end
