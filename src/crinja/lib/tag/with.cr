# The `with` statement makes it possible to create a new inner scope. Variables set within this
# scope are not visible outside of the scope.
#
# ```
# {% with %}
#     {% set foo = 42 %}
#     {{ foo }}           # => foo is 42 here
# {% endwith %}
# {{ foo }}               # => undefined
# ```
#
# Because it is common to set variables at the beginning of the scope, you can do that within the
# with statement. The following two examples are equivalent:
#
# ```
# {% with foo = 42 %}
#     {{ foo }}
# {% endwith %}
#
# {% with %}
#     {% set foo = 42 %}
#     {{ foo }}
# {% endwith %}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#with-statement) for details.
class Crinja::Tag::With < Crinja::Tag
  name "with", "endwith"

  def interpret_output(renderer : Crinja::Renderer, tag_node : TagNode)
    env = renderer.env
    args = Parser.new(tag_node.arguments, renderer.env.config)

    var_defs = Hash(String, Type).new
    args.parse_with_tag_arguments.each do |variable, expression|
      var_defs[variable.name] = renderer.env.evaluate(expression)
    end

    renderer.env.with_scope(var_defs) do
      renderer.render(tag_node.block)
    end
  end

  private class Parser < ArgumentsParser
    def parse_with_tag_arguments
      parse_keyword_list(keyword_separator_token: Crinja::Parser::Token::Kind::KW_ASSIGN)
    end
  end
end
