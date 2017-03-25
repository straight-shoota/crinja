module Crinja::Parser
  class UnknownTagException < ParserError
  end

  module BuildTag
    def build_tag_node(start_token)
      name_token = token_stream.next_token
      raise "Tag musst have a name token" unless name_token.kind == Kind::NAME

      tag = template.env.context.tags[name_token.value]

      if tag.nil?
        raise UnknownTagException.new(name_token.value)
      end

      if tag.is_a?(Tag::EndTag)
        end_token = next_token
        raise "expected closing tag sequence `%}` for end tag #{tag}" unless end_token.kind == Kind::TAG_END
        build_end_tag_node(start_token, end_token, tag)
        return nil
      end

      arguments = [] of Statement

      root = Statement::MultiRoot.new(start_token)

      statement_parser = StatementParser.new(self, root)
      statement_parser.expected_end_token = Kind::TAG_END

      statement_parser.build

      node = Node::Tag.new(start_token, tag, root.varargs, root.kwargs)
      node.parent = @parent.as(Node)
      node.end_token = current_token

      add_trim_to_last_sibling if node.trim_left?

      unless node.end_name.nil?
        @parent << node
        @parent = node
        return nil
      end

      node
    end

    def build_end_tag_node(start_token, end_token, end_tag)
      while !@parent.is_a?(Node::Root)
        parent_tag = @parent.as(Node::Tag)
        @parent = @parent.parent.not_nil!

        if parent_tag.end_name == end_tag.name
          add_trim_to_last_child if start_token.trim_left
          parent_tag.end_tag_tokens = {start: start_token, end: end_token}
          break
        else
          raise TemplateSyntaxError.new(start_token, "Mismatched end tag, expected: #{parent_tag.end_name} got #{end_tag.name}")
        end
      end
    end
  end
end
