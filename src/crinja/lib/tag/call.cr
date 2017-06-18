# In some cases it can be useful to pass a `Macro` to another macro. For this purpose, you can use
# the special call block. The following example shows a macro that takes advantage of the call
# functionality and how it can be used:
#
# ```
# {% macro render_dialog(title, class='dialog') -%}
#     <div class="{{ class }}">
#         <h2>{{ title }}</h2>
#         <div class="contents">
#             {{ caller() }}
#         </div>
#     </div>
# {%- endmacro %}

# {% call render_dialog('Hello World') %}
#     This is a simple dialog rendered by using a macro and
#     a call block.
# {% endcall %}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#call) for details.
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

  private class Parser < ArgumentsParser
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
