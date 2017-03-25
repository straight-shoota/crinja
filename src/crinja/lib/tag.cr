module Crinja
  abstract class Tag
    include Importable

    class TagException < RuntimeException
      def initialize(tag, msg, node = nil)
        super("#{tag}: #{msg} #{node}")
      end
    end

    def interpret_output(env : Crinja::Environment, tag_node : Node::Tag)
      Node::RenderedOutput.new(String.build do |io|
        interpret(io, env, tag_node)
      end)
    end

    abstract def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)

    def end_tag : String?
      nil
    end

    macro name(name, end_tag = nil)
      def name : String
        {{ name }}
      end

      def end_tag : String?
        {{ end_tag }}
      end
    end

    def render_children(env : Crinja::Environment, node : Node)
      output = Node::OutputList.new
      node.children.each do |node|
        output << node.render(env)
      end
      output
    end

    private def expect_name(node, name = nil)
      expect_name(node, name) { }
    end

    private def expect_name(node, name = nil)
      if node.is_a?(Statement::Name) && (name.nil? || (name.is_a?(Array) && name.includes?(node.name)) || name === node.name)
        yield node.name
        return node.name
      end

      nil
    end

    class Library < FeatureLibrary(Tag)
      TAGS_WITH_BODY = [For, If, Set, Macro, Block]
      SINGLE_TAGS    = [Else, ElseIf, Include, Extends]

      def register_defaults
        TAGS_WITH_BODY.each do |name|
          tag = name.new
          self << tag
          self << EndTag.new(tag)
        end
        SINGLE_TAGS.each do |name|
          tag = name.new
          self << tag
        end
      end
    end
  end
end

require "./tag/*"
