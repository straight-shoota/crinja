require "./visitor"

module Crinja
  class Visitor::Renderer < Visitor
    def initialize(@env : Environment)
    end

    def visit(node : Node)
      raise node.class.to_s
    end

    def visit(node : Node::Root)
      visit(node.children)
    end

    def visit(nodes : Array(Node))
      Node::OutputList.new.tap do |output|
        nodes.each do |node|
          output << node.accept(self)
        end
      end
    end

    def visit(node : Node::Text)
      Node::RenderedOutput.new node.value(@env.config.trim_blocks, @env.config.lstrip_blocks)
    end

    def visit(node : Node::Tag)
      node.tag.interpret_output(@env, node)
    end

    def visit(node : Node::Note)
      Node::RenderedOutput.new ""
    end

    def visit(node : Node::Expression)
      result = node.statement.not_nil!.evaluate(@env)

      if @env.context.autoescape?
        result = SafeString.escape(result)
      end

      Node::RenderedOutput.new result.to_s
    end
  end
end
