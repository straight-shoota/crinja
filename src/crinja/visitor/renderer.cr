require "./visitor"

abstract class Crinja::Visitor
  class Renderer < Visitor
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

    def self.trim_text(node, trim_blocks = false, lstrip_blocks = false)
      Crinja::Util::StringTrimmer.trim(
        node.token.value,
        node.trim_left || (trim_blocks && node.left_is_block),
        node.trim_right || (lstrip_blocks && node.right_is_block),
        node.left_is_block,
        node.right_is_block && lstrip_blocks
      )
    end

    def visit(node : Node::Text)
      trim_blocks = @env.config.trim_blocks
      lstrip_blocks = @env.config.lstrip_blocks

      Node::RenderedOutput.new Crinja::Visitor::Renderer.trim_text(node, @env.config.trim_blocks, @env.config.lstrip_blocks)
    end

    def visit(node : Node::Tag)
      node.tag.interpret_output(@env, node)
    end

    def visit(node : Node::Note)
      Node::RenderedOutput.new ""
    end

    def visit(node : Node::Expression)
      result = node.statement.accept(@env.evaluator)

      if @env.context.autoescape?
        result = SafeString.escape(result)
      end

      Node::RenderedOutput.new result.to_s
    end
  end
end
