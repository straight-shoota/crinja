module Crinja
  abstract class Tag
    include Importable

    class TagException < RuntimeException
      def initialize(tag, msg, node = nil)
        super("#{tag}: #{msg} #{node}")
      end
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

    def render_children(io : IO, env : Crinja::Environment, node : Node)
      node.children.each do |node|
        node.render(io, env)
      end
    end

    class Library < FeatureLibrary(Tag)
      TAGS_WITH_BODY = [For, If, Set, Macro]
      SINGLE_TAGS    = [Else, ElseIf, Include]

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
