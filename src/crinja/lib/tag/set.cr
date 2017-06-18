# Inside code blocks, you can also assign values to variables. Assignments at top level (outside of
# blocks, macros or loops) are exported from the template like top level macros and can be imported
# by other templates.
#
# Assignments use the set tag and can have multiple targets:
#
# ```
# {% set navigation = [('index.html', 'Index'), ('about.html', 'About')] %}
# {% set key, value = call_something() %}
# ```
#
# It is also possible to use block assignments to capture the contents of a `set` block into a
# variable name. Instead of using an equals sign and a value, you just write the variable name and
# then everything until `{% endset %}` is captured.
#
# {% set navigation %}
#     <li><a href="/">Index</a>
#     <li><a href="/downloads">Downloads</a>
# {% endset %}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#assignments) for details.
class Crinja::Tag::Set < Crinja::Tag
  name "set", "endset"

  private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    env = renderer.env
    args = ArgumentsParser.new(tag_node.arguments)

    if tag_node.arguments.size == 2
      # IDENTIFIER + EOF
      name = args.current_token.value
      args.next_token
      value = renderer.render(tag_node.block).value
      env.context[name] = SafeString.new(value)
      args.close
    else
      args.parse_keyword_list.each do |identifier, expr|
        env.context[identifier.name] = env.evaluate(expr)
      end
      # raise TemplateSyntaxError.new(tag_node, "Tag `set` requires either a single name argument (set block) or at least one assignment", exc)

      args.close
    end
  end

  def has_block?(node : TagNode)
    node.arguments.size <= 2
  end
end
