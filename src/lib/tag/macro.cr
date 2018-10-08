# Macros are comparable with functions in regular programming languages. They are useful to put
# often used idioms into reusable functions to not repeat yourself (“DRY”).
#
# Here’s a small example of a macro that renders a form element:
#
# ```
# {% macro input(name, value='', type='text', size=20) -%}
#     <input type="{{ type }}" name="{{ name }}" value="{{
#         value|e }}" size="{{ size }}">
# {%- endmacro %}
# ```
#
# The macro can then be called like a function in the namespace:
#
# ```
# {{ input('username') }}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#macros) for details.
class Crinja::Tag::Macro < Crinja::Tag
  name "macro", "endmacro"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments, renderer.env.config)

    name, defaults = parser.parse_macro_node

    instance = MacroFunction.new(name, tag_node.block, renderer)

    defaults.each do |key, value|
      instance.defaults[key] = if value.is_a?(AST::ExpressionNode)
                                 env.evaluate(value)
                               else
                                 env.undefined(key)
                               end
    end

    renderer.template.register_macro name, instance

    Renderer::RenderedOutput.new("")
  end

  private class Parser < ArgumentsParser
    def parse_macro_node
      name = parse_identifier
      expect Kind::LEFT_PAREN

      call = parse_call_expression(name)

      defaults = Hash(String, AST::ExpressionNode | Nil).new
      call.argumentlist.children.each do |arg_expr|
        if (arg = arg_expr).is_a?(AST::IdentifierLiteral)
          defaults[arg.name] = nil
        else
          raise TemplateSyntaxError.new(arg_expr, "Invalid statement #{arg_expr} in macro def")
        end
      end

      call.keyword_arguments.each do |arg, value|
        defaults[arg.name] = value
      end

      close

      {name.name, defaults}
    end

    private def parse_macro_arguments_definition
      hash = Hash(String, AST::ExpressionNode | Nil).new

      should_read = current_token.kind != Kind::RIGHT_PAREN
      while should_read
        should_read = false

        keyword = parse_literal

        if keyword.is_a?(AST::IdentifierLiteral)
          value = nil
          if_token Kind::KW_ASSIGN do
            next_token
            value = parse_expression
          end

          hash[keyword.name] = value
        else
          unexpected_token Kind::IDENTIFIER
        end

        if current_token.kind == Kind::COMMA
          should_read = true
          next_token
        end
      end

      hash
    end
  end

  class MacroFunction
    include Callable

    getter name, defaults, children, catch_kwargs, catch_varargs, caller

    def initialize(@name : String, @children : AST::NodeList, @renderer : Renderer, @defaults = Variables.new, @caller = false)
      @catch_varargs = false
      @catch_kwargs = !@defaults.empty?
    end

    def call(arguments : Arguments)
      arguments.defaults = @defaults

      arguments.env.with_scope(arguments.to_h) do |context|
        context.merge!({
          "varargs" => arguments.varargs,
          "kwargs"  => arguments.kwargs,
        })

        SafeString.build do |io|
          Crinja::Renderer.new(@renderer.template, arguments.env).render(children).value(io)
        end
      end
    end

    def arguments
      defaults.keys
    end
  end
end
