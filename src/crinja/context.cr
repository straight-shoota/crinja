module Crinja
  class Context < ScopeMap(String, Type)
    AUTOESCAPE_DEFAULT = true

    getter operators, filters, functions, tags, tests

    setter autoescape : Bool?
    property parent_templates : Array(String) = [] of String
    setter super_block : Array(Node)?

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
    end

    def parent : Context?
      @parent.as(Context?)
    end

    def merge!(bindings)
      super(Crinja::Bindings.cast(bindings).as(Hash(String, Type)))
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

    def super_block
      return @super_block unless @super_block.nil?
      parent.try(&.super_block)
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
end
