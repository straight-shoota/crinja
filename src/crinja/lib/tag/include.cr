module Crinja
  class Tag::Include < Tag
    name "include"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      raw_value = tag_node.varargs.first.value(env).raw

      include_name = if raw_value.is_a?(Array)
                       raw_value.map &.to_s
                     else
                       raw_value.to_s
                     end
      vararg_index = 1
      context = env.context
      ignore_missing = false

      if tag_node.varargs.size > vararg_index
        expect_name(tag_node.varargs[vararg_index], "ignore") do
          vararg_index += 1
          expect_name(tag_node.varargs[vararg_index], "missing") do
            vararg_index += 1
            ignore_missing = true
          end || raise TemplateSyntaxError.new(tag_node.varargs[vararg_index].token, "expected `missing` after `ignore`")
        end
      end

      if tag_node.varargs.size > vararg_index
        expect_name(tag_node.varargs[vararg_index], ["with", "without"]) do |with_or_without|
          vararg_index += 1
          expect_name(tag_node.varargs[vararg_index], "context") do
            vararg_index += 1
            if with_or_without == "without"
              context = env.global_context
            end
          end || raise TemplateSyntaxError.new(tag_node.varargs[vararg_index].token, "expected `context` after `#{with_or_without}`")
        end || raise TemplateSyntaxError.new(tag_node.varargs[vararg_index].token, "expected `without` or `ignore`")
      end

      begin
        env.logger.debug "loading include #{include_name}"
        template = env.get_template(include_name)
        template.render(io, context)
      rescue error : TemplateNotFoundError
        raise error unless ignore_missing
      end
    end
  end
end
