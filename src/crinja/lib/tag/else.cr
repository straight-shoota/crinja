module Crinja
  class Tag::Else < Tag
    name "else"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
    end
  end
end
