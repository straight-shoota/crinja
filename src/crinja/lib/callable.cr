require "../error"

module Crinja
  class Crinja::UnknownArgumentException < Crinja::RuntimeError
    def initialize(name, arguments)
      super "unknown argument \"#{name}\" for #{arguments.inspect}"
    end
  end

  module CallableMod
    abstract def call(arguments : Arguments) : Value
  end

  alias CallableProc = Arguments -> Type
  alias Callable = CallableMod | CallableProc

  # This holds arguments and environment information for function, filter, test and macro calls.
  struct Arguments
    property varargs : Array(Value)
    property target : Value?
    property kwargs : Hash(String, Value)
    property defaults : Hash(String, Type)
    property env : Environment
    property! renderer : Renderer

    def initialize(@env, @varargs = [] of Value, @kwargs = Hash(String, Value).new, @defaults = Hash(String, Type).new, @target = nil)
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
end
