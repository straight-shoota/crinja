# The extends tag can be used to extend one template from another. You can have multiple extends
# tags in a file, but only one of them may be executed at a time.
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#template-inheritance) for details.
class Crinja::Tag::Extends < Crinja::Tag
  name "extends"

  private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    env = renderer.env
    parser = ArgumentsParser.new(tag_node.arguments, renderer.env.config)
    name_expr = parser.parse_expression
    parser.close

    extends_name = env.evaluate(name_expr).to_s

    # raise TemplateSyntaxError.new(tag_node.token, "Cannot extend from multiple parents") unless env.parent_template.nil?
    env.context.extend_path_stack << extends_name

    template = env.get_template(extends_name)
    renderer.extend_parent_templates << template
  end
end
