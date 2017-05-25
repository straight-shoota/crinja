module Crinja
  class Tag::Call < Tag
    name "call", "endcall"

    def interpret(io : IO, env : Environment, tag_node : Node::Tag)
      call_stmt = tag_node.varargs.first

      defaults = Hash(String, Type).new

      if call_stmt.is_a?(Statement::Subexpression)
        subexpression = call_stmt
        defaults[subexpression.child.as(Statement::Name).name] = nil
        call_stmt = tag_node.varargs[1]
      end

      env.with_scope do |ctx|
        env.context.register_macro Tag::Macro::MacroFunction.new "caller", tag_node.children, defaults, caller: true

        io << call_stmt.accept(env.evaluator)
      end
    end
  end
end
