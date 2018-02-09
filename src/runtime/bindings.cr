# This module provides some methods to cast datastructures with Crystal types like `Array(String)`
# to Crinja datastructures like `Array(Value)`.
module Crinja::Bindings
  # Casts an object with hash-like interface to `Variables`, which can be
  # used for name lookup.
  def self.cast_variables(variables) : Variables
    type_hash = Variables.new
    variables.each do |k, v|
      type_hash[k.to_s] = cast_value(v)
    end
    type_hash
  end

  # Casts any value to `Value`.
  def self.cast_value(value) : Value
    case value
    when Hash
      Value.new cast_dictionary(value)
    when NamedTuple
      Value.new cast_named_tuple(value)
    when Tuple
      Value.new cast_tuple(value)
    when Array
      Value.new cast_list(value)
    when Range
      # TODO: Implement range trough pyobject `getitem`
      Value.new value.to_a
    when Iterator
      Value.new cast_iterator(value)
    when Char
      Value.new value.to_s
    when Value
      value
    else
      if !value.is_a?(Value) && value.responds_to?(:raw)
        # JSON::Any & YAML::Any
        cast_value(value.raw)
      else
        Value.new(value)
      end
    end
  end

  # Casts an object with hash-like interface to `Dictionary`.
  def self.cast_dictionary(value) : Dictionary
    type_hash = Dictionary.new
    value.each do |k, v|
      type_hash[cast_value(k)] = cast_value(v)
    end
    type_hash
  end

  # Casts a `NamedTuple` to `Dictionary`, converting symbol keys to strings.
  def self.cast_named_tuple(value) : Dictionary
    type_hash = Dictionary.new
    value.each do |k, v|
      type_hash[Value.new k.to_s] = cast_value(v)
    end
    type_hash
  end

  # Casts an object with iterable interface to `Array(Value)`.
  def self.cast_list(array) : Array(Value)
    array.map do |item|
      cast_value(item)
    end
  end

  # Casts a tuple to `PyTuple`.
  def self.cast_tuple(tuple) : PyTuple
    PyTuple.from(tuple)
  end

  def self.cast_iterator(iterator : Iterator(Value)) : Iterator(Value)
    iterator
  end

  def self.cast_iterator(iterator) : Iterator(Value)
    Value::Iterator.new(iterator)
  end
end
