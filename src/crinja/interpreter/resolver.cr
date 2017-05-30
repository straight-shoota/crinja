module Crinja::Resolver
  # Resolves an objects item.
  # Analogous to `__getitem__` in Jinja2.
  def self.resolve_item(name, object)
    object = object.raw if object.is_a?(Value)
    raise UndefinedError.new(name.to_s, "#{object.class} is undefined") if object.is_a?(Undefined)

    value = Undefined.new(name.to_s)
    if object.is_a?(Array) && name.is_a?(Int)
      value = object[name]
    end
    if object.responds_to?(:getitem)
      value = object.getitem(name)
    end
    if value.is_a?(Undefined) && object.responds_to?(:getattr)
      value = object.getattr(name)
    end
    if value.is_a?(Undefined)
      value = resolve_with_hash_accessor(name, object)
    end

    if value.is_a?(Value)
      value = value.raw
    end

    value.as(Type)
  end

  # Resolves an objects attribute.
  # Analogous to `getattr` in Jinja2.
  def self.resolve_attribute(name, object)
    object = object.raw if object.is_a?(Value)
    raise UndefinedError.new(name.to_s, "#{object.class} is undefined") if object.is_a?(Undefined)

    value = Undefined.new(name.to_s)
    if object.responds_to?(:getattr)
      value = object.getattr(name)
    end
    if value.is_a?(Undefined) && object.responds_to?(:getitem)
      value = object.getitem(name)
    end
    if value.is_a?(Undefined)
      value = resolve_with_hash_accessor(name, object)
    end

    if value.is_a?(Value)
      value = value.raw
    end

    value.as(Type)
  end

  def self.resolve_with_hash_accessor(name, object)
    if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(Tuple)
      begin
        return object[name.to_s]
      rescue KeyError
      end
    end

    Undefined.new(name.to_s)
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

  def execute_call(target, varargs : Array(Type), kwargs : Hash(String, Type))
    execute_call(target,
      varargs.map { |a| Value.new(a) },
      kwargs.each_with_object(Hash(String, Value).new) do |(k, v), hash|
        hash[k] = Value.new(v)
      end
    )
  end

  def execute_call(callable, varargs : Array(Value), kwargs : Hash(String, Value))
    arguments = Arguments.new(self, varargs, kwargs)
    resolve_callable(callable).call(arguments)
  end

  def resolve_callable(identifier : String) : Callable
    if context.has_macro?(identifier.to_s)
      context.macro(identifier.to_s)
    else
      callable = resolve(identifier)

      if callable.is_a?(Callable)
        # FIX: Why is `.as(Callable)` needed here?
        return callable.as(Callable)
      end

      raise TypeError.new(Value.new(callable), "`#{identifier}` is not callable")
    end
  end

  def resolve_callable(callable : Value) : Callable
    if callable.undefined?
      raise TypeError.new(callable, "#{callable} is undefined")
    end

    raw = callable.raw
    if raw.is_a?(Callable)
      return raw.as(Callable)
    end

    raise TypeError.new(callable, "#{callable} is not callable")
  end
end
