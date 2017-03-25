module Crinja::Parser
  alias Node = Crinja::Node

  class TemplateParser < Base
    include BuildExpression
    include BuildTag

    getter template, root

    @parent : Node

    def initialize(@template : Template, @root : Node::Root)
      @token_stream = TokenStream.new(Lexer::TemplateLexer.new(template.env.config, template.string))
      @parent = root
    end

    def build
      while token_stream.next_token?
        node = next_node

        @parent << node unless node.nil?
      end

      if @parent != root
        raise ParserError.new "Missing end tag for #{@parent}: #{@parent.as(Node::Tag).end_name}"
      end

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
      else
        raise "Unexpected token #{token}"
      end
    end

    def build_text_node(token)
      node = Node::Text.new(token)

      if (sibling = last_sibling).nil?
        if @parent.trim_right?
          node.trim_left = true
        end
      else
        node.trim_left = true if sibling.trim_right_after_end?
      end

      node.parent = @parent.as(Node)
      node
    end

    def last_sibling
      @parent.children.last unless @parent.nil? || @parent.children.empty?
    end

    def add_trim_to_last_sibling
      if !(sibling = last_sibling).nil? && sibling.is_a?(Node::Text)
        sibling.trim_right = true
      end
    end

    def add_trim_to_last_child
      if (children = last_sibling.try(&.children)) && children.size > 0 && (child = children.last).is_a?(Node::Text)
        child.trim_right = true
      end
    end
  end
end
