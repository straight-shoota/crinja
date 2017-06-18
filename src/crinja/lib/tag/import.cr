# Crinja supports putting often used code into macros. These macros can go into different templates
# and get imported from there. It’s important to know that imports can be cached and imported templates
# don’t have access to the current template variables, just the globals by default.
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#import) for details.
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

      template.macros.each do |key, value|
        env.context.macros["#{context_var}.#{key}"] = value
      end
    end
  end
end
