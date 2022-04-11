require "./crinja"
require "./error"

# This holds arguments and environment information for function, filter, test and macro calls.
struct Crinja::Arguments
  # Returns the variable arguments of the call.
  getter varargs : Array(Value)

  # Returns the target of the call (if any).
  getter target : Value?

  # Returns the keyword arguments of the call.
  getter kwargs : Hash(String, Value)

  # Default argument values defined by the call implementation.
  getter defaults : Variables

  # :nodoc:
  setter defaults : Variables

  # Returns the crinja environment.
  getter env : Crinja

  def initialize(@env, @varargs = [] of Value, @kwargs = Hash(String, Value).new, @defaults = Variables.new, @target = nil)
  end

  def [](name : String) : Value
    if kwargs.has_key?(name)
      kwargs[name]
    elsif index = defaults.index { |k, v| k == name }
      if varargs.size > index
        varargs[index]
      else
        default(name)
      end
    else
      raise UnknownArgumentError.new(name, self)
    end
  end

  def fetch(name, default : Value)
    fetch(name) { default }
  end

  def fetch(name, default = nil)
    fetch name, Value.new(default)
  end

  def fetch(name)
    value = self[name]
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
    kwargs.has_key?(name) || (index = defaults.index { |k, v| k == name }) && varargs.size > index
  end

  def default(name : Symbol)
    default(name.to_s)
  end

  def default(name : String)
    Value.new defaults[name]
  end

  class UnknownArgumentError < RuntimeError
    def initialize(name, arguments)
      super "unknown argument \"#{name}\" for #{arguments.inspect}"
    end
  end

  class Error < RuntimeError
    property callee
    property argument : String?

    def self.new(argument : Symbol | String, msg = nil, cause = nil)
      new nil, msg, cause, argument: argument
    end

    def initialize(@callee : Callable | Callable::Proc | Operator?, msg = nil, cause = nil, @argument = nil)
      super msg, cause
    end

    def message
      arg = ""
      arg = " argument: #{argument}" unless argument.nil?
      "#{super} (called: #{callee}#{arg})"
    end
  end
end
