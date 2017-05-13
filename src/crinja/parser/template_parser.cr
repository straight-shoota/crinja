module Crinja::Parser
  alias Node = Crinja::Node

  class TemplateParser < Base
    include BuildExpression
    include BuildTag

    getter template, root

    @parent : Node

    def initialize(@template : Template, @root : Node::Root)
      @token_stream = TokenStream.new(Lexer::TemplateLexer.new(template.env.config, template.source))
      @logger = @template.env.logger
      @parent = root
    end

    def build
      while token_stream.next_token?
        node = next_node

        @parent << node unless node.nil?
      end

      if @parent != root
        raise TemplateSyntaxError.new token_stream.current_token, "Missing end tag for #{@parent}: #{@parent.as(Node::Tag).end_name}"
      end

      logger.debug root.inspect

      root
    end

    def next_node
      token = token_stream.current_token
      case token.kind
      when Kind::FIXED
        build_text_node(token)
      when Kind::EXPR_START
        build_expression_node(token)
      when Kind::TAG_START
        build_tag_node(token)
      when Kind::NOTE
        build_note_node(token)
      else
        raise "Unexpected token #{token}"
      end
    end

    def build_text_node(token)
      node = Node::Text.new(token)

      if (sibling = last_sibling).nil?
        node.trim_left = @parent.trim_right?
        node.left_is_block = @parent.block?
      else
        node.trim_left = sibling.trim_right_after_end?
        node.left_is_block = sibling.block?
      end

      node.parent = @parent.as(Node)
      node
    end

    def build_note_node(token)
      node = Node::Note.new(token)

      set_trim_for_last_sibling(node.trim_left?, true)

      node.parent = @parent.as(Node)
      node
    end

    def last_sibling
      @parent.children.last unless @parent.nil? || @parent.children.empty?
    end

    def set_trim_for_last_sibling(trim, is_block = false)
      if !(sibling = last_sibling).nil? && sibling.is_a?(Node::Text)
        sibling.trim_right = trim
        sibling.right_is_block = is_block
      end
    end

    def set_trim_for_last_child(trim, is_block = false)
      if (children = last_sibling.try(&.children)) && children.size > 0 && (child = children.last).is_a?(Node::Text)
        child.trim_right = trim
        child.right_is_block = is_block
      end
    end
  end
end
