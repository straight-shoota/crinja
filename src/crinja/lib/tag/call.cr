class Crinja::Tag::Call < Crinja::Tag
  name "call", "endcall"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments)
    defaults, call = parser.parse_call_tag

    instance = Tag::Macro::MacroFunction.new "caller", tag_node.block, renderer, caller: true
    defaults.each do |key, value|
      instance.defaults[key] = if value.is_a?(AST::ExpressionNode)
                                 env.evaluate(value)
                               else
                                 value
                               end
    end

    env.context.register_macro instance

    Renderer::RenderedOutput.new(env.evaluate(call).to_s)
  end

  class Parser < ArgumentsParser
    def parse_call_tag
      defaults = Hash(String, AST::ExpressionNode | Nil).new

      if_token Kind::LEFT_PAREN do
        location = current_token.location
        next_token
        args = parse_call_expression(AST::IdentifierLiteral.new("call").at(location))

        args.argumentlist.children.each do |arg_expr|
          if (arg = arg_expr).is_a?(AST::IdentifierLiteral)
            defaults[arg.name] = nil
          else
            raise TemplateSyntaxError.new(arg_expr, "Invalid statement #{arg_expr} in call def")
          end
        end

        args.keyword_arguments.each do |arg, value|
          defaults[arg.name] = value
        end
      end

      identifier = parse_identifier
      expect Kind::LEFT_PAREN
      call = parse_call_expression(identifier)

      close

      {defaults, call}
    end
  end
end
