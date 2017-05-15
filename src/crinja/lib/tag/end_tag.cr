module Crinja
  class Tag::EndTag < Tag
    # this constructor is required, otherwise elements of Array(Class(Tag)) could not be instantiated
    # without arguments, even if none of them is a EndTag
    def initialize
      @tag = Tag::If.new
      @name = "invalid"
      raise "INVALID CONSTRUCTOR"
    end

    getter :name

    def initialize(@tag : Tag, @name)
    end

    def end_tag
      nil
    end

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
    end
  end
end
