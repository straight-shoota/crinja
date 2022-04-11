class Crinja
  # :nodoc:
  macro callable(kind, defaults = nil, name = nil)
    %defaults = Crinja::Variables.new
    {% if defaults.is_a?(NamedTupleLiteral) || defaults.is_a?(HashLiteral) %}
      {% for key in defaults.keys %}
        %defaults[{{ key.id.stringify }}] = Crinja::Value.new({{ defaults[key] }})
      {% end %}
    {% else %}
      {% name = defaults %}
    {% end %}

    %block = ->(arguments : Crinja::Arguments) do
      env = arguments.env
      Crinja::Value.new begin
        {{ yield }}
      end
    end

    {% if defaults.is_a?(StringLiteral) %}
      {% name = defaults %}
    {% end %}

    %instance = Crinja::Callable::Instance.new(%block, %defaults, {{ name.is_a?(NilLiteral) ? nil : name.id.stringify }})

    {% unless name.is_a?(NilLiteral) %}
    {{ kind }}::Library.defaults << %instance
    {% end %}

    %instance
  end

  # This macro returns a `Crinja::Callable` proc which implements a `Crinja::Test`.
  #
  # *defaults* are set as default values in the `Crinja::Arguments` object,
  # which a call to this proc receives.
  #
  # If a *name* is provided, the created proc will automatically be registered as a default test
  # at `Crinja::Test::Library`.
  #
  # The macro takes a *block* which will be the main body for the proc. There, the following
  # variables are available:
  # * *arguments* : `Crinja::Arguments` - Call arguments from the caller including *defaults*.
  # * *env* : `Crinja` - The current environment.
  # * *target* : `Crinja::Value` - The subject of the test. Short cut for `arguments.target`.
  macro test(defaults = nil, name = nil, &block)
    Crinja.callable(Crinja::Test, {{ defaults }}, {{ name }}) do
      target = arguments.target!

      {{ block.body }}
    end
  end

  # This macro returns a `Crinja::Callable` proc which implements a `Crinja::Filter`.
  #
  # *defaults* are set as default values in the `Crinja::Arguments` object,
  # which a call to this proc receives.
  #
  # If a *name* is provided, the created proc will automatically be registered as a default filter
  # at `Crinja::Filter::Library`.
  #
  # The macro takes a *block* which will be the main body for the proc. There, the following
  # variables are available:
  # * *arguments* : `Crinja::Arguments` - Call arguments from the caller including *defaults*.
  # * *env* : `Crinja` - The current environment.
  # * *target* : `Crinja::Value` - The value which is to be filtered. Short cut for `arguments.target`.
  macro filter(defaults = nil, name = nil, &block)
    Crinja.callable(Crinja::Filter, {{ defaults }}, {{ name }}) do
      target = arguments.target!

      {{ yield }}
    end
  end

  # This macro returns a `Crinja::Callable` proc which implements a `Crinja::Function`.
  #
  # *defaults* are set as default values in the `Crinja::Arguments` object,
  # which a call to this proc receives.
  #
  # If a *name* is provided, the created proc will automatically be registered as a default golbal
  # function at `Crinja::Function::Library`.
  #
  # The macro takes a *block* which will be the main body for the proc. There, the following
  # variables are available:
  # * *arguments* : `Crinja::Arguments` - Call arguments from the caller including *defaults*.
  # * *env* : `Crinja` - The current environment.
  macro function(defaults = nil, name = nil, &block)
    Crinja.callable(Crinja::Function, {{ defaults }}, {{ name }}) do
      {{ block.body }}
    end
  end

  module Callable
  end
end

require "../arguments"

class Crinja
  # A Callable is a Crinja type object that can be called from an expression call. These include
  # functions, macros, tests and filters.
  # It can be implemented by an object or module which inherits from `CallableMod` or using a proc.
  # In either way, the callable must respond to `#call(arguments : Arguments)` and return `Value` or
  # a value accepted by `Crinja.value`.
  # It must be added to the environment's feature library to be useable from template.
  # There are macros in `Crinja` which allow an easy implementation as a proc.
  module Callable
    abstract def call(arguments : Arguments)

    alias Proc = Arguments -> Value

    class Instance
      include Callable

      getter proc : Proc
      getter defaults : Variables
      getter name : String?

      def initialize(@proc, @defaults = {} of String => Value, @name = nil)
      end

      def call(arguments : Arguments) : Crinja::Value
        @proc.call(arguments)
      end
    end

    def to_s(io)
      me = self
      if me.responds_to?(:name) && (name = me.name)
        io << name
      else
        io << "*unnamed_callable_#{object_id}*"
      end
      io << "("

      if me.responds_to?(:defaults)
        me.defaults.each_with_index do |(key, value), i|
          io << ", " if i > 0
          io << key
          io << "=" << Finalizer.stringify(value, in_struct: true) unless value.is_a?(Undefined)
        end
      else
        io << "?"
      end

      io << ")"
    end
  end
end
