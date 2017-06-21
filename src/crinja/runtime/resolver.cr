module Crinja::Resolver
  # Resolves an objects item. Tries `resolve_getattr` it `getitem` returns undefined.
  # Analogous to `__getitem__` in Jinja2.
  def self.resolve_item(name, object)
    raise UndefinedError.new(name.to_s, "#{object.class} is undefined") if object.is_a?(Undefined)

    value = resolve_getitem(name, object)

    if value.is_a?(Undefined)
      value = self.resolve_getattr(name, object)
    end

    cast_type value, name
  end

  # ditto
  def self.resolve_item(name, value : Value)
    self.resolve_item(name, value.raw)
  end

  # Resolve an objects item.
  def self.resolve_getitem(name, object)
    value = Undefined.new(name.to_s)

    if object.responds_to?(:__getitem__)
      value = object.__getitem__(name)
    end
    if object.is_a?(Indexable) && name.responds_to?(:to_i)
      value = object[name.to_i]
    end
    value
  end

  # :ditto:
  def self.resolve_getitem(name, value : Value)
    self.resolve_getitem(name, value.raw)
  end

  # Resolves an objects attribute. Tries `resolve_getitem` it `getitem` returns undefined.
  # Analogous to `getattr` in Jinja2.
  def self.resolve_attribute(name, object)
    raise UndefinedError.new(name.to_s, "#{object.class} is undefined") if object.is_a?(Undefined)

    value = self.resolve_getattr(name, object)

    if value.is_a?(Undefined)
      value = self.resolve_getitem(name, object)
    end

    cast_type value, name
  end

  private def self.cast_type(value, name)
    if value.is_a?(Value)
      value = value.raw
    end

    if value.is_a?(Type)
      value
    else
      raise TypeError.new("#{name} is of type #{value.class}, can't cast to Crinja::Type")
    end
  end

  # ditto
  def self.resolve_attribute(name, value : Value)
    self.resolve_attribute(name, value.raw)
  end

  def self.resolve_getattr(name, object)
    if object.responds_to?(:getattr)
      object.getattr(name)
    else
      self.resolve_with_hash_accessor(name, object)
    end
  end

  # ditto
  def self.resolve_getattr(name, value : Value)
    self.resolve_getattr(name, value.raw)
  end

  def self.resolve_method(name, object) : Callable | Callable::Proc?
    if object.responds_to? :__call__
      object.__call__(name).as(Callable | Callable::Proc)
    else
      nil
    end
  end

  # ditto
  def self.resolve_method(name, value : Value)
    self.resolve_method(name, value.raw)
  end

  def self.resolve_with_hash_accessor(name, object : Type)
    if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(PyTuple) && !object.is_a?(String | SafeString)
      begin
        return object[name.to_s]
      rescue KeyError
      end
    end

    Undefined.new(name.to_s)
  end

  # ditto
  def self.resolve_with_hash_accessor(name, value : Value)
    self.resolve_with_hash_accessor(name, value.raw)
  end

  # Resolves a dig.
  def self.resolve_dig(name : String, object : Type)
    identifier, _, rest = name.partition('.')

    resolved = resolve_attribute(identifier, object)
    if rest != ""
      resolve_dig(rest, resolved)
    else
      resolved
    end
  end

  # :ditto:
  def self.resolve_dig(name, object : Type)
    resolve_attribute(name, object)
  end

  # :ditto:
  def self.resolve_dig(name, value : Value)
    self.resolve_dig(name, value.raw)
  end

  # Resolves a variable in the current context.
  def resolve(name : String)
    if functions.has_key?(name)
      value = functions[name]
    else
      value = context[name]
    end
    logger.debug "resolved string #{name}: #{value.inspect}"
    value
  end

  def execute_call(callable, varargs : Array(Type), kwargs : Hash(String, Type), target : Value? = nil)
    execute_call(callable,
      varargs.map { |a| Value.new(a) },
      kwargs.each_with_object(Hash(String, Value).new) do |(k, v), hash|
        hash[k] = Value.new(v)
      end,
      target: target
    )
  end

  def execute_call(callable,
                   varargs : Array(Value) = [] of Value,
                   kwargs : Hash(String, Value) = {} of String => Value,
                   target : Value? = nil)
    arguments = Callable::Arguments.new(self, varargs, kwargs, target: target)
    callable = resolve_callable!(callable)
    execute_call callable, arguments
  end

  def execute_call(callable : Callable | Callable::Proc, arguments : Callable::Arguments)
    if callable.responds_to?(:defaults)
      arguments.defaults = callable.defaults
    end

    callable.call(arguments)
  end

  def call_filter(name, target, *args)
    unless target.is_a?(Value)
      unless target.is_a?(Type)
        target = Crinja::Bindings.cast_value(target)
      end
      target = Value.new(target)
    end
    execute_call(filters[name], *args, target: target)
  end

  def resolve_callable(identifier)
    if context.has_macro?(identifier.to_s)
      context.macro(identifier.to_s)
    else
      resolve(identifier.to_s)
    end
  end

  def resolve_callable!(identifier : Callable | Callable::Proc)
    identifier
  end

  def resolve_callable!(identifier) : Callable | Callable::Proc
    callable = resolve_callable(identifier)

    if callable.is_a? Undefined
      raise TypeError.new(Value.new(callable), "#{identifier.inspect} is undefined")
    end

    if callable.is_a? Callable
      # FIXME: Explicit cast should not be necessary.
      return callable.as(Callable | Callable::Proc)
    else
      raise TypeError.new(Value.new(callable), "`#{identifier.inspect}` is not callable")
    end
  end

  def resolve_callable!(callable : Value)
    resolve_callable!(callable.raw)
  end
end
