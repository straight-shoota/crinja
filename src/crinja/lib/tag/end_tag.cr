module Crinja
  class Tag::EndTag < Tag
    # this constructor is required, otherwise elements of Array(Class(Tag)) could not be instantiated
    # without arguments, even if none of them is a EndTag
    def initialize
      @tag = Tag::If.new
      raise "INVALID CONSTRUCTOR"
    end

    def initialize(@tag : Tag)
    end

    def name
      @tag.end_tag.not_nil!
    end

    def end_tag
      nil
    end

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
    end
  end
end
