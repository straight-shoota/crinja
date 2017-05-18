module Crinja
  class Tag::Macro < Tag
    name "macro", "endmacro"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      call = tag_node.varargs.first.as(Statement::Call)
      name = call.target.as(Statement::Name).name

      instance = MacroFunction.new(name, tag_node.children)

      call.varargs.each do |arg_stmt|
        if (arg = arg_stmt).is_a?(Statement::Name)
          instance.defaults[arg.name] = nil
        else
          raise TemplateSyntaxError.new(arg_stmt.token, "Invalid statement #{arg_stmt} in macro def")
        end
      end

      call.kwargs.each do |arg, value|
        instance.defaults[arg] = value.value(env).raw
      end

      tag_node.template.register_macro name, instance
    end

    class MacroFunction
      include CallableMod
      # include PyWrapper

      getter name, defaults, children, catch_kwargs, catch_varargs, caller

      def initialize(@name : String, @children : Array(Node), @defaults = Hash(String, Type).new, @caller = false)
        @catch_varargs = false
        @catch_kwargs = !@defaults.empty?
      end

      def call(arguments : Arguments)
        arguments.defaults = @defaults
        arguments.env.with_scope(arguments.to_h) do |context|
          context.merge!({
            "varargs" => arguments.varargs,
            "kwargs"  => arguments.kwargs,
          })

          output = Node::OutputList.new
          children.each do |child|
            output << child.render(arguments.env)
          end
          SafeString.new output.value
        end
      end

      def arguments
        defaults.keys
      end

      # getattr name, arguments, defaults, catch_kwargs, catch_varargs
    end
  end
end
