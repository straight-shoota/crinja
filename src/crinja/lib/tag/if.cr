module Crinja
  class Tag::If < Tag
    name "if", "endif"

    def validate_arguments
      validate_argument 0, klass = Node::Statement
      validate_arguments_size 1
    end

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      current_branch_active = evaluate_node(tag_node, env)

      tag_node.children.each do |node|
        if (tnode = node).is_a?(Node::Tag) && (tnode.tag.is_a?(Tag::ElseIf) || tnode.tag.is_a?(Tag::Else))
          break if current_branch_active

          current_branch_active = evaluate_node(tnode, env)
        else
          node.render(io, env) if current_branch_active
        end
      end
    end

    def evaluate_node(tag_node, env : Crinja::Environment)
      if tag_node.name == "else"
        return true
      end

      value = tag_node.varargs.first.value(env)
      value.truthy?
    end
  end
end
