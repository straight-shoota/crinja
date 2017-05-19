class Crinja::Tag
  class Raw < Tag
    name "raw", "endraw"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      if (fixed = tag_node.children.first).is_a?(Node::Text)
        io << fixed.token.value
      else
        raise TemplateSyntaxError.new(tag_node.token, "raw tag expexts exactly one fixed content node inside")
      end
    end
  end
end
