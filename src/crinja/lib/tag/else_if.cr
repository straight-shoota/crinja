module Crinja
  class Tag::ElseIf < Tag
    name "elif"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
    end
  end
end
