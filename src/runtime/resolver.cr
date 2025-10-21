module Crinja::Resolver
  # Resolves an objects attribute. Tries `resolve_getattr`.
  # Analogous to `getattr` in Jinja2.
  def self.resolve_attribute(name, object : Value) : Value
    raise UndefinedError.new(name.to_s) if object.undefined?

    value = self.resolve_getattr(name, object)

    if value.undefined?
      if object.indexable? && name.responds_to?(:to_i)
        if v = object[name.to_i]?
          return Value.new v
        end
      end
    end

    value
  end

  # :ditto:
  def self.resolve_attribute(name, value) : Value
    self.resolve_attribute(name, Value.new value)
  end

  def self.resolve_getattr(name : Value, value : Value) : Value
    object = value.raw
    if object.responds_to?(:crinja_attribute)
      Value.new object.crinja_attribute(name)
    else
      self.resolve_with_hash_accessor(name, value)
    end
  end

  # :ditto:
  def self.resolve_getattr(name, value) : Value
    resolve_getattr(Value.new(name), Value.new(value))
  end

  def self.resolve_method(name, object) : Callable | Callable::Proc?
    if object.responds_to?(:crinja_call) && (callable = object.crinja_call(name))
      return ->(arguments : Arguments) do
        # wrap the return value of the proc as a Value
        Value.new callable.not_nil!.call(arguments)
      end.as(Callable::Proc)
    end
  end

  # :ditto:
  def self.resolve_method(name, value : Value) : Callable | Callable::Proc?
    self.resolve_method(name, value.raw)
  end

  def self.resolve_with_hash_accessor(name : Value, value : Value) : Value
    object = value.raw
    if object.responds_to?(:[]?) && !object.is_a?(Array) && !object.is_a?(Crinja::Tuple) && !object.is_a?(String | SafeString)
      if value = object[name.to_s]?
        return Value.new value
      end
    end

    Value.new Undefined.new(name.to_s)
  end

  # :ditto:
  def self.resolve_with_hash_accessor(name, value : Value) : Value
    self.resolve_with_hash_accessor(name, value.raw)
  end

  # Resolves a dig.
  def self.resolve_dig(name : String, object) : Value
    identifier, _, rest = name.partition('.')

    resolved = resolve_attribute(identifier, object)
    if rest != ""
      resolve_dig(rest, resolved)
    else
      resolved
    end
  end

  # :ditto:
  def self.resolve_dig(name, object) : Value
    resolve_attribute(name, object)
  end

  # :ditto:
  def self.resolve_dig(name : Value, value : Value) : Value
    self.resolve_dig(name.to_s, value.raw)
  end

  # Resolves a variable in the current context.
  def resolve(name : String) : Value
    if functions.has_key?(name)
      Value.new functions[name]
    else
      context[name]
    end
  end

  def execute_call(callable,
                   varargs : Array(Value) = [] of Value,
                   kwargs : Variables = Variables.new,
                   target : Value? = nil) : Value
    arguments = Arguments.new(self, varargs, kwargs, target: target)
    callable = resolve_callable!(callable)
    execute_call callable, arguments
  end

  def execute_call(callable : Callable | Callable::Proc, arguments : Arguments) : Value
    if callable.responds_to?(:defaults)
      arguments.defaults = callable.defaults
    end

    Value.new callable.call(arguments)
  end

  def call_filter(name : String, target) : Value
    call_filter(name, Value.new(target))
  end

  def call_filter(name : String, target : Value, varargs = [] of Value, kwargs = Variables.new) : Value
    execute_call(filters[name], varargs, kwargs, target: target)
  end

  def resolve_callable(identifier) : Value
    identifier = identifier.to_s
    if context.has_macro?(identifier)
      Value.new context.macro(identifier)
    else
      resolve(identifier)
    end
  end

  def resolve_callable!(identifier : Callable | Callable::Proc) : Callable | Callable::Proc
    identifier
  end

  def resolve_callable!(identifier : Value) : Callable | Callable::Proc
    return identifier.as_callable.as(Callable | Callable::Proc) if identifier.callable?

    callable = resolve_callable(identifier)

    if callable.undefined?
      raise TypeError.new(callable, "#{identifier.as_undefined.name} is undefined")
    end

    if callable.callable?
      # FIXME: Explicit cast should not be necessary.
      return callable.as_callable.as(Callable | Callable::Proc)
    else
      raise TypeError.new(callable, "`#{identifier.inspect}` is not callable")
    end
  end
end
