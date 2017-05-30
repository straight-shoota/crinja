module Crinja
  class Tag::Set < Tag
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
        begin
          args.parse_keyword_list.each do |identifier, expr|
            env.context[identifier.name] = env.evaluate(expr)
          end
        rescue exc
          raise TemplateSyntaxError.new(tag_node, "Tag `set` requires either a single name argument (set block) or at least one assignment", exc)
        end

        args.close
      end
    end

    def has_block?(node : TagNode)
      node.arguments.size <= 2
    end
  end
end
