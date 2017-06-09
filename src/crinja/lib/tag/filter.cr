class Crinja::Tag::Filter < Crinja::Tag
  name "filter", "endfilter"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments)
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

  def interpret(io : IO, env : Environment, tag_node : TagNode)
    raise "Unsupported operation"
  end
end
