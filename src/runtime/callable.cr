require "../error"

class Crinja
  # :nodoc:
  macro callable(kind, defaults = nil, name = nil)
    %defaults = Crinja::Variables.new
    {% if defaults.is_a?(NamedTupleLiteral) || defaults.is_a?(HashLiteral) %}
    {% for key in defaults.keys %}
      %defaults[{{ key.id.stringify }}] = {{ defaults[key] }}
    {% end %}
    {% else %}
      {% name = defaults %}
    {% end %}

    %block = ->(arguments : Crinja::Callable::Arguments) do
      env = arguments.env
      {{ yield }}.as(Crinja::Type)
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
      ({{ block.body }}).as(Crinja::Type)
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
      ({{ yield }}).as(Crinja::Type)
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
      ({{ yield }}).as(Crinja::Type)
    end
  end

  # A Callable is a Crinja type object that can be called from an expression call. These include
  # functions, macros, tests and filters.
  # It can be implemented by an object or module which inherits from `CallableMod` or using a proc.
  # In either way, the callable must respond to `#call(arguments : Arguments)` and return a `Value`
  # and must be added to the environments feature library to be useable from template.
  # There are macros in `Crinja` which allow an easy implementation as a proc.
  module Callable
    abstract def call(arguments : Arguments) : Value

    alias Proc = Arguments -> Type

    class Instance
      include Callable

      getter proc : Proc
      getter defaults : Variables
      getter name : String?

      def initialize(@proc, @defaults = {} of String => Type, @name = nil)
      end

      def call(arguments : Arguments)
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

    # This holds arguments and environment information for function, filter, test and macro calls.
    struct Arguments
      property varargs : Array(Value)
      property target : Value?
      property kwargs : Hash(String, Value)
      property defaults : Variables
      property env : Crinja
      property! renderer : Renderer

      def initialize(@env, @varargs = [] of Value, @kwargs = Hash(String, Value).new, @defaults = Variables.new, @target = nil)
      end

      def [](name : Symbol) : Value
        self.[name.to_s]
      end

      def [](name : String) : Value
        if kwargs.has_key?(name)
          kwargs[name]
        elsif index = defaults.key_index(name)
          if varargs.size > index
            varargs[index]
          else
            default(name)
          end
        else
          raise UnknownArgumentException.new(name, self)
        end
      end

      def fetch(name, default : Type = nil)
        fetch(name) { default }
      end

      def fetch(name)
        value = self.[name]
        if value.raw.nil?
          Value.new(yield)
        else
          value
        end
      end

      def target!
        if (t = target).nil?
          raise UndefinedError.new("undefined target")
        else
          t
        end
      end

      def to_h
        [@kwargs.keys, @defaults.keys].flatten.uniq.each_with_object(Hash(String, Value).new) do |key, hash|
          hash[key] = self[key]
        end
      end

      def is_set?(name : Symbol)
        is_set?(name.to_s)
      end

      def is_set?(name : String)
        kwargs.has_key?(name) || (index = defaults.key_index(name)) && varargs.size > index
      end

      def default(name : Symbol)
        default(name.to_s)
      end

      def default(name : String)
        Value.new defaults[name]
      end
    end

    class UnknownArgumentException < RuntimeError
      def initialize(name, arguments)
        super "unknown argument \"#{name}\" for #{arguments.inspect}"
      end
    end

    class ArgumentError < RuntimeError
      property callee : Callable | Callable::Proc | Operator?
      property argument : String?

      def self.new(argument : Symbol | String, msg = nil, cause = nil)
        new nil, msg, cause, argument: argument
      end

      def initialize(@callee, msg = nil, cause = nil, @argument = nil)
        super msg, cause
      end

      def message
        arg = ""
        arg = " argument: #{argument}" unless argument.nil?
        "#{super} (called: #{callee}#{arg})"
      end
    end
  end
end
