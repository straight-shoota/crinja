module Crinja
  class Tag::If < Tag
    name "if", "endif"

    private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
      env = renderer.env
      current_branch_active = evaluate_node(tag_node, env)

      tag_node.block.children.each do |node|
        if (tnode = node).is_a?(TagNode) && (tnode.name == "elif" || tnode.name == "else")
          break if current_branch_active

          current_branch_active = evaluate_node(tnode, env)
        else
          renderer.render(node).value(io) if current_branch_active
        end
      end
    end

    def evaluate_node(tag_node, env : Crinja::Environment)
      if tag_node.name == "else"
        return true
      end

      arguments = ArgumentsParser.new(tag_node.arguments)
      expression = arguments.parse_expression

      if expression.is_a?(Parser::Empty)
        raise TemplateSyntaxError.new(tag_node, "#{tag_node.name} tag missing condition")
      end

      arguments.close

      value = env.evaluator.value(expression)
      value.truthy?
    end
  end

  class Tag::Else < Tag
    name "else"

    def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    end
  end

  class Tag::Elif < Tag
    name "elif"

    def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    end
  end
end
