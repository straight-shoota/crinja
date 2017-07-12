# Filter sections allow you to apply regular `Crinja::Filter` filters on a block of template data.
# Just wrap the code in the special filter block:
#
# ```
# {% filter upper %}
#     This text becomes uppercase
# {% endfilter %}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#id11) for details.
class Crinja::Tag::Filter < Crinja::Tag
  name "filter", "endfilter"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments, renderer.env.config)
    placeholder, expression = parser.parse_filter_tag

    placeholder.value = renderer.render(tag_node.block).value

    result = renderer.env.evaluate(expression)

    Renderer::RenderedOutput.new(SafeString.new(result.to_s).to_s)
  end

  private class Parser < ArgumentsParser
    def parse_filter_tag
      placeholder = left = AST::ValuePlaceholder.new(nil).at(current_token.location)

      while true
        identifier = parse_identifier

        if current_token.kind == Kind::LEFT_PAREN
          next_token

          call = parse_call_expression(identifier)
        else
          call = parse_call_expression(identifier, with_parenthesis: false)
        end

        left = AST::FilterExpression.new(left, identifier, call.argumentlist, call.keyword_arguments).at(left, call)

        if current_token.kind != Kind::PIPE
          break
        end

        next_token
      end

      close

      return placeholder, left
    end
  end
end
