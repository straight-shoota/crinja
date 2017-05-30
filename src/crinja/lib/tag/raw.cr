class Crinja::Tag
  class Raw < Tag
    name "raw", "endraw"

    private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
      ArgumentsParser.new(tag_node.arguments).close
      if (fixed = tag_node.block.children.first).is_a?(Parser::FixedString)
        io << fixed.string
      else
        raise TemplateSyntaxError.new(tag_node, "raw tag expexts exactly one fixed content node inside")
      end
    end
  end
end
