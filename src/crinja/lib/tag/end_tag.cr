class Crinja::Tag::EndTag < Crinja::Tag
  # this constructor is required, otherwise elements of Array(Class(Tag)) could not be instantiated
  # without arguments, even if none of them is a EndTag
  def initialize
    @start_tag = Tag::If.new
    @name = "invalid"
    raise "INVALID CONSTRUCTOR"
  end

  getter :name, :start_tag

  def initialize(@start_tag : Tag, @name)
  end

  def end_tag
    nil
  end

  private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
  end
end
