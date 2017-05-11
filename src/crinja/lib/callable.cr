require "../error"

module Crinja
  class UnknownArgumentException < Crinja::RuntimeError
    def initialize(name, arguments)
      super "unknown argument \"#{name}\" for #{arguments.inspect}"
    end
  end

  module Callable
    abstract def call(arguments : Arguments) : Value

    def create_arguments(env : Environment, varargs : Array(Value) = [] of Value, kwargs : Hash(::String, Value) = Hash(::String, Value).new, defaults : Hash(::String, Type) = Hash(::String, Type).new)
      Arguments.new(env, varargs, kwargs, defaults)
    end

    macro arguments(defs)
      def create_arguments(env : Environment, varargs : Array(Value) = [] of Value, kwargs : Hash(::String, Value) = Hash(::String, Value).new)
        defaults = Hash(::String, Type).new
        {% for key, value in defs %}
        defaults[{{ key.id.stringify }}] = {{ value }}
        {% end %}
        create_arguments(env, varargs, kwargs, defaults)
      end
    end

    struct Arguments
      property varargs : Array(Value)
      property target : Value?
      property caller : Value?
      property kwargs : Hash(String, Value)
      property defaults : Hash(String, Type)
      property env : Environment

      def initialize(@env, @varargs = [] of Value, @kwargs = Hash(String, Value).new, @defaults = Hash(String, Type).new)
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

      def to_h
        [@kwargs.keys, @defaults.keys].flatten.uniq.each_with_object(Hash(String, Value).new) do |key, hash|
          hash[key] = self[key]
        end
      end

      def is_set?(name : Symbol)
        is_set?(name.to_s)
      end

      def is_set?(name : String)
        kwargs.has_key?(name)
      end

      def default(name : Symbol)
        default(name.to_s)
      end

      def default(name : String)
        Value.new defaults[name]
      end
    end
  end
end
