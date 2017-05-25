module Crinja
  class Tag::If < Tag
    name "if", "endif"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      current_branch_active = evaluate_node(tag_node, env)

      tag_node.children.each do |node|
        if (tnode = node).is_a?(Node::Tag) && (tnode.tag.is_a?(Tag::ElseIf) || tnode.tag.is_a?(Tag::Else))
          break if current_branch_active

          current_branch_active = evaluate_node(tnode, env)
        else
          Visitor::Renderer.new(env).visit(node).value(io) if current_branch_active
        end
      end
    end

    def evaluate_node(tag_node, env : Crinja::Environment)
      if tag_node.name == "else"
        return true
      end

      raise TemplateSyntaxError.new(tag_node.token, "additional args for if tag") if tag_node.varargs.size > 1
      raise TemplateSyntaxError.new(tag_node.token, "if tag without condition") if tag_node.varargs.size == 0
      raise TemplateSyntaxError.new(tag_node.token, "additional kwargs for if tag") if tag_node.kwargs.size > 0

      value = env.evaluator.value(tag_node.varargs.first)
      value.truthy?
    end
  end
end
