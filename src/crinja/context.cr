require "./value"

module Crinja
  # A context holds information about the state of runtime execution.
  # This includes tracking of local variables and call stacks, access to global features and configuration settings.
  #
  # Contexts form a hierarchical structure, where sub-contexts inherit from their parents, but don't
  # pollute the outer contexts with local scoped values.
  # Creating instances is not useful as it’s created automatically at various stages of the template evaluation and should not be created by hand.
  class Context < Util::ScopeMap(String, Type)
    AUTOESCAPE_DEFAULT = false

    getter extend_path_stack, import_path_stack, include_path_stack, macro_stack

    property autoescape : Bool?
    setter block_context : NamedTuple(name: String, index: Int32)?

    def initialize(bindings : Hash(String, Type))
      initialize(nil, bindings)
    end

    def initialize(parent : Context? = nil, bindings : Hash(String, Type)? = nil)
      super(parent, bindings)

      @macros = Hash(String, Crinja::Tag::Macro::MacroFunction).new

      @extend_path_stack = CallStack.new(:extend, parent.try(&.extend_path_stack))
      @import_path_stack = CallStack.new(:import, parent.try(&.import_path_stack))
      @include_path_stack = CallStack.new(:include, parent.try(&.include_path_stack))
      @macro_stack = CallStack.new(:macro, parent.try(&.macro_stack))
    end

    # Returns the parent context. It must not be altered.
    def parent : Context?
      @parent.as(Context?)
    end

    # Returns the local variables whose scope is this context.
    def session_bindings
      self.scope
    end

    # Returns macros defined in the root context.
    def macros
      if (p = parent).nil?
        @macros
      else
        p.macros
      end
    end

    def all_macros
      all = @macros
      unless (p = parent).nil?
        all.merge!(p.all_macros)
      end
      all
    end

    def has_macro?(name)
      @macros.has_key?(name) || parent.try(&.has_macro?(name))
    end

    def macro(name) : Callable
      @macros[name]? || parent.try(&.macro(name)) || raise "Macro #{name} is not registered"
    end

    def register_macro(makro)
      @macros[makro.name] = makro
    end

    def merge!(context : Crinja::Context)
      super(context.scope)
    end

    # Merges values in *bindings* into local scope.
    def merge!(bindings)
      super(Crinja::Bindings.cast(bindings).as(Hash(String, Type)))
    end

    # Set variable *key* to value *value* in local scope.
    def []=(key : String, value : Hash(String, Type))
      self[key] = Crinja::Bindings.cast(value)
    end

    # Returns an undefined value.
    def undefined
      Undefined.new
    end

    # Determines if autoescape is enabled in this or any parent context.
    def autoescape?
      if (autoescape = @autoescape).nil?
        if (p = parent).nil?
          AUTOESCAPE_DEFAULT
        else
          p.autoescape?
        end
      else
        autoescape
      end
    end

    def unpack(vars : Array(String), values : Array(Type))
      if vars.size == 1
        self[vars[0]] = values
      else
        vars.each_with_index do |var, i|
          value = values[i]
          self[var] = if value.is_a?(Value)
                        value.raw
                      else
                        value
                      end
        end
      end
    end

    def unpack(vars : Array(String), values : Array(Value))
      unpack(vars, values.map(&.raw))
    end

    def unpack(vars : Array(String), values : TypeValue | Hash(Type, Type) | Tuple(Type, Type))
      raise "cannot unpack multiple values" if vars.size > 1
      self[vars.first] = values.as(Type)
    end

    def block_context
      return @block_context unless @block_context.nil?
      parent.try(&.block_context)
    end

    class CallStack
      @stack : Array(String) = [] of String

      def initialize(@kind : Symbol, @parent : CallStack?)
      end

      def includes?(path : String)
        @stack.includes?(path) || @parent.try(&.includes?(path))
      end

      def <<(path : String)
        raise TagCycleException.new(@kind) if includes?(path)

        push_without_check(path)
      end

      def push_without_check(path : String)
        @stack << path
      end

      def pop
        if @stack.empty?
          @parent.try(&.pop)
        else
          @stack.pop
        end
      end
    end
  end
end
