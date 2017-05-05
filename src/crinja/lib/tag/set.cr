module Crinja
  class Tag::Set < Tag
    name "set", "endset"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      if tag_node.varargs.size == 1 && (name_node = tag_node.varargs[0]).is_a?(Statement::Name)
        # block set
        name = name_node.name
        value = render_children(env, tag_node).value
        env.context[name] = SafeString.new(value)
      elsif tag_node.kwargs.size > 0
        # expression set
        tag_node.kwargs.each do |name, value|
          env.context[name] = value.value(env).raw
        end
      else
        raise TemplateSyntaxError.new(tag_node.token, "Tag `set` requires either a single name argument (set block) or at least one assignment")
      end
    end

    def end_tag_for(node : Node::Tag) : String?
      node.varargs.size > 0 ? end_tag : nil
    end
  end
end
