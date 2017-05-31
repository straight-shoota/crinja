class Crinja::Tag::Import < Crinja::Tag
  name "import"

  private def interpret(io : IO, renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = ArgumentsParser.new(tag_node.arguments)
    name_expr = parser.parse_expression

    context_var = parser.if_identifier "as" do
      parser.next_token
      parser.current_token.value
    end

    parser.close

    include_name = env.evaluate(name_expr).to_s

    env.context.import_path_stack << include_name

    template = env.get_template(include_name)

    if context_var.nil?
      template.render(env)
    else
      child = Environment.new(env)
      template.render(child)

      env.errors += child.errors

      child_bindings = child.context.session_bindings
      child.context.macros.each do |key, value|
        child_bindings[key] = value
      end

      env.context[context_var] = child_bindings
    end
  end
end
