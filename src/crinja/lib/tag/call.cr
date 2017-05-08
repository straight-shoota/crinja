module Crinja
  class Tag::Call < Tag
    name "call", "endcall"

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      call_stmt = tag_node.varargs.first

      call_stmt.value(env)
    end
  end
end
