require "../error"

module Crinja
  class UnknownArgumentException < Crinja::RuntimeError
    def initialize(name, arguments)
      super "unknown argument \"#{name}\" for #{arguments.inspect}"
    end
  end

  module Callable
    abstract def call(arguments : Arguments) : Type

    def create_arguments(env : Environment, varargs : Array(Any) = [] of Any, kwargs : Hash(String, Any) = Hash(String, Any).new, defaults : Hash(String, Type) = Hash(String, Type).new)
      Arguments.new(env, varargs, kwargs, defaults)
    end

    macro arguments(defs)
      def create_arguments(env : Environment, varargs : Array(Any) = [] of Any, kwargs : Hash(String, Any) = Hash(String, Any).new)
        defaults = Hash(String, Type).new
        {% for key, value in defs %}
        defaults[{{ key.id.stringify }}] = {{ value }}
        {% end %}
        create_arguments(env, varargs, kwargs, defaults)
      end
    end

    class Arguments
      property varargs : Array(Any)
      property target : Any?
      property caller : Any?
      property kwargs : Hash(String, Any)
      property defaults : Hash(String, Type)
      property env : Environment

      def initialize(@env, @varargs = [] of Any, @kwargs = Hash(String, Any).new, @defaults = Hash(String, Type).new)
      end

      def [](name : Symbol) : Any
        self.[name.to_s]
      end

      def [](name : String) : Any
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
        [@kwargs.keys, @defaults.keys].flatten.uniq.each_with_object(Hash(String, Any).new) do |key, hash|
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
        Any.new defaults[name]
      end
    end
  end
end
