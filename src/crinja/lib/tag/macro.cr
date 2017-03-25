module Crinja
  class Tag::Macro < Tag
    name "macro", "endmacro"

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      call = tag_node.varargs.first.as(Statement::Call)
      name = call.target.as(Statement::Name).name

      instance = MacroInstance.new(name, env, tag_node.children)

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

      tag_node.root.template.macros[name] = instance
    end

    class MacroInstance
      include Callable
      # include PyWrapper

      getter name, defaults, children, env, catch_kwargs, catch_varargs, caller

      def initialize(@name : String, @env : Environment, @children : Array(Node), @defaults = Hash(String, Type).new)
        @catch_varargs = false
        @catch_kwargs = false
        @caller = false
      end

      def create_arguments(varargs : Array(Any) = [] of Any, kwargs : Hash(String, Any) = Hash(String, Any).new)
        create_arguments(varargs, kwargs, defaults)
      end

      def call(arguments : Arguments)
        env.with_scope(arguments.to_h) do |context|
          context.merge!({
            "varargs" => arguments.varargs,
            "kwargs"  => arguments.kwargs,
            "caller"  => arguments.caller,
          })

          output = Node::OutputList.new
          children.each do |child|
            output << child.render(env)
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
