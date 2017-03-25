module Crinja
  class Tag::Set < Tag
    name "set", "endset"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      if tag_node.varargs.size == 1 && (name_node = tag_node.varargs[0]).is_a?(Statement::Name)
        # block set
        name = name_node.name
        value = String.build do |block_io|
          render_children(block_io, env, tag_node)
        end
        env.context[name] = SafeString.new(value.to_s)
      elsif tag_node.kwargs.size == 1
        # expression set
        name = tag_node.kwargs.first_key
        value = tag_node.kwargs.first_value.value(env)
        env.context[name] = value.raw
      else
        raise TagException.new(self, "Malformed tag: Requires either a single name argument (set block) or an assignment", tag_node)
      end
    end

    def end_tag_for(node : Node::Tag) : String?
      node.varargs.size > 0 ? end_tag : nil
    end
  end
end
