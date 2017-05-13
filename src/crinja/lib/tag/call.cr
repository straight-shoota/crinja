module Crinja
  class Tag::Call < Tag
    name "call", "endcall"

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      call_stmt = tag_node.varargs.first

      puts tag_node.inspect

      env.with_scope do |ctx|
        ctx.macros["caller"] = Tag::Macro::MacroInstance.new "caller", env, tag_node.children

        call_stmt.value(env)
      end
    end
  end
end
