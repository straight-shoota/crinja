module Crinja
  class Tag::Include < Tag
    name "include"

    private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
      env = renderer.env
      parser = IncludeParser.new(tag_node.arguments)
      source_expression, ignore_missing, with_context = parser.parse_include_tag

      source = env.evaluate(source_expression)
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

    class IncludeParser < ArgumentsParser
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
end
