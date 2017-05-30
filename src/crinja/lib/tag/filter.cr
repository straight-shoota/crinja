class Crinja::Tag::Filter < Crinja::Tag
  name "filter", "endfilter"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments)
    name, expression = parser.parse_filter_tag

    filter = env.filters[name]

    target = Value.new renderer.render(tag_node.block).value

    argumentlist = env.evaluate(expression.argumentlist).as(Array(Type)).map { |a| Value.new a }
    keyword_arguments = expression.keyword_arguments.each_with_object(Hash(String, Value).new) do |(keyword, value), args|
      args[keyword.name] = env.evaluator.value(value)
    end

    result = filter.call Arguments.new(env, argumentlist, keyword_arguments, target: target)

    Renderer::RenderedOutput.new(SafeString.new(result.to_s).to_s)
  end

  class Parser < ArgumentsParser
    def parse_filter_tag
      name = parse_identifier

      if current_token.kind == Kind::LEFT_PAREN
        next_token

        call = parse_call_expression(name)
      else
        call = parse_call_expression(name, with_parenthesis: false)
      end

      close

      {name.name, call}
    end
  end

  def interpret(io : IO, env : Environment, tag_node : TagNode)
    raise "Unsupported operation"
  end
end
