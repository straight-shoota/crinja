module Crinja::Resolver
  # Resolves an objects item. Tries `resolve_getattr` it `getitem` returns undefined.
  # Analogous to `__getitem__` in Jinja2.
  def self.resolve_item(name : Value, object : Value) : Value
    raise UndefinedError.new(name.to_s) if object.undefined?

    value = resolve_getitem(name, object)

    if value.undefined?
      value = self.resolve_getattr(name, object)
    end

    value
  end

  # ditto
  def self.resolve_item(name, raw) : Value
    self.resolve_item(Value.new(name), Value.new(raw))
  end

  # Resolve an objects item.
  def self.resolve_getitem(name : Value, object : Value) : Value
    value = Undefined.new(name.to_s)

    raw_object = object.raw
    if raw_object.responds_to?(:__getitem__)
      value = raw_object.__getitem__(name)
    end

    raw = name.raw
    if object.indexable? && raw.responds_to?(:to_i)
      begin
        value = object[raw.to_i]
      rescue IndexError
        value = Undefined.new(name.to_s)
      end
    end

    Value.new value
  end

  # :ditto:
  def self.resolve_getitem(name, value) : Value
    self.resolve_getitem(Value.new(name), Value.new(value))
  end

  # Resolves an objects attribute. Tries `resolve_getitem` it `getitem` returns undefined.
  # Analogous to `getattr` in Jinja2.
  def self.resolve_attribute(name, object : Value) : Value
    raise UndefinedError.new(name.to_s) if object.undefined?

    value = self.resolve_getattr(name, object)

    if value.undefined?
      value = self.resolve_getitem(name, object)
    end

    value
  end

  # ditto
  def self.resolve_attribute(name, value) : Value
    self.resolve_attribute(name, Value.new value)
  end

  def self.resolve_getattr(name : Value, value : Value) : Value
    object = value.raw
    if object.responds_to?(:getattr)
      Value.new object.getattr(name)
    else
      self.resolve_with_hash_accessor(name, value)
    end
  end

  # ditto
  def self.resolve_getattr(name, value) : Value
    resolve_getattr(Value.new(name), Value.new(value))
  end

  def self.resolve_method(name, object) : Callable | Callable::Proc?
    if object.responds_to?(:__call__) && (callable = object.__call__(name))
      return ->(arguments : Callable::Arguments) do
        # wrap the return value of the proc as a Value
        Value.new callable.not_nil!.call(arguments)
      end.as(Callable::Proc)
    end
  end

  # ditto
  def self.resolve_method(name, value : Value) : Callable | Callable::Proc?
    self.resolve_method(name, value.raw)
  end

  def self.resolve_with_hash_accessor(name : Value, value : Value) : Value
    object = value.raw
    if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(PyTuple) && !object.is_a?(String | SafeString)
      begin
        return Value.new object[name.to_s]
      rescue KeyError
      end
    end

    Value.new Undefined.new(name.to_s)
  end

  # ditto
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
  def self.resolve_dig(name, value : Value) : Value
    self.resolve_dig(name, value.raw)
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
    arguments = Callable::Arguments.new(self, varargs, kwargs, target: target)
    callable = resolve_callable!(callable)
    execute_call callable, arguments
  end

  def execute_call(callable : Callable | Callable::Proc, arguments : Callable::Arguments) : Value
    if callable.responds_to?(:defaults)
      arguments.defaults = callable.defaults
    end

    Value.new callable.call(arguments)
  end

  def call_filter(name, target : Value, *args) : Value
    execute_call(filters[name], *args, target: target)
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
