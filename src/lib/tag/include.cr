# The include statement is useful to include a template and return the rendered contents of that
# file into the current namespace:
#
# ```
# {% include 'header.html' %}
#     Body
# {% include 'footer.html' %}
# ```
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#include) for details.
class Crinja::Tag::Include < Crinja::Tag
  name "include"

  private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments, renderer.env.config)
    source_expression, ignore_missing, with_context = parser.parse_include_tag

    begin
      source = env.evaluate(source_expression)
    rescue error : UndefinedError
      if renderer.env.config.liquid_compatibility_mode
        # enables use of `{% include file.name %}` => `source = "file.name"`
        source = String.build do |io|
          Visitor::Source.new(io).visit(tag_node.arguments)
        end.strip
      else
        raise error
      end
    end

    if source.is_a?(Array)
      include_name = source.map &.to_s
    else
      include_name = source.to_s
    end

    context = env.global_context unless with_context

    env_context = env.context

    begin
      env.logger.debug "loading include #{include_name}"
      template = env.get_template(include_name)
      template.render(io, context)
    rescue error : TemplateNotFoundError
      raise error unless ignore_missing
    end
  end

  private class Parser < ArgumentsParser
    def parse_include_tag
      source_expression = parse_expression

      ignore_missing = false

      if_identifier "ignore" do
        next_token
        expect_identifier "missing"

        ignore_missing = true
      end

      with_context = current_token.value != "without"

      if_identifier ["with", "without"] do
        next_token
        expect_identifier "context"
      end

      close

      {source_expression, ignore_missing, with_context}
    end
  end
end
