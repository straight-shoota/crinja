# The `do` tag works exactly like the regular variable expression (`{{ ... }}`) except it doesn’t print anything.
# This can be used to modify lists:
#
# ```
# {% do navigation.append('a string') %}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#expression-statement) for details.
class Crinja::Tag::Do < Crinja::Tag
  name "do"

  private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    env = renderer.env
    evaluate_node(tag_node, env)
  end

  def evaluate_node(tag_node, env : Crinja)
    arguments = ArgumentsParser.new(tag_node.arguments, env.config)
    expression = arguments.parse_expression
    arguments.close
    env.evaluate(expression)
  end
end
