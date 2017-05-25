module Crinja
  class Tag::Extends < Tag
    name "extends"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      parent_template = tag_node.varargs.first.accept(env.evaluator).to_s

      # raise TemplateSyntaxError.new(tag_node.token, "Cannot extend from multiple parents") unless env.parent_template.nil?
      env.context.extend_path_stack << parent_template

      template = env.get_template(parent_template)
      env.extend_parent_templates << template
    end
  end
end