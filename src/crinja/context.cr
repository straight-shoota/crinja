module Crinja
  class Context < ScopeMap(String, Type)
    AUTOESCAPE_DEFAULT = true

    getter operators, filters, functions, tags, tests
    getter extend_path_stack, import_path_stack, include_path_stack, macro_stack

    setter autoescape : Bool?
    setter block_context : NamedTuple(name: String, index: Int32)?

    def initialize(bindings : Hash(String, Type))
      initialize(nil, bindings)
    end

    def initialize(parent : Context? = nil, bindings : Hash(String, Type)? = nil)
      super(parent, bindings)

      @operators = Operator::Library.new
      @functions = Function::Library.new
      @filters = Filter::Library.new
      @tags = Tag::Library.new
      @tests = Test::Library.new
      @macros = Hash(String, Crinja::Tag::Macro::MacroInstance).new

      @extend_path_stack = CallStack.new(:extend, parent.try(&.extend_path_stack))
      @import_path_stack = CallStack.new(:import, parent.try(&.import_path_stack))
      @include_path_stack = CallStack.new(:include, parent.try(&.include_path_stack))
      @macro_stack = CallStack.new(:macro, parent.try(&.macro_stack))
    end

    def parent : Context?
      @parent.as(Context?)
    end

    def session_bindings
      self.scope
    end

    def macros
      if (p = parent).nil?
        @macros
      else
        p.macros
      end
    end

    def merge!(bindings)
      super(Crinja::Bindings.cast(bindings).as(Hash(String, Type)))
    end

    def []=(key : String, value : Hash(String, Crinja::Type))
      self[key] = Crinja::Bindings.cast(value)
    end

    def undefined
      Undefined.new
    end

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
      vars.each_with_index do |var, i|
        value = values[i]
        self[var] = if value.is_a?(Any)
                      value.raw
                    else
                      value
                    end
      end
    end

    def unpack(vars : Array(String), values : Array(Any))
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

    def inspect(io)
      super(io)
      io << " libraries="
      {% for library in ["operators", "functions", "filters", "tags"] %}
      io << " " << {{ library.id.stringify }} << "=["
      {{ library.id }}.keys.each do |item|
        io << item << ", "
      end
      io << "]"
      {% end %}
    end
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
