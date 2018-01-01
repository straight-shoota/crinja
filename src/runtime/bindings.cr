# This module provides some methods to cast datastructures with Crystal types like `Array(String)`
# to Crinja datastructures like `Array(Crinja::Type)`.
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

  # Casts any value to `Crinja::Type`.
  def self.cast_value(value) : Crinja::Type
    case value
    when Hash
      self.cast_hash(value)
    when NamedTuple
      self.cast_named_tuple(value)
    when Tuple
      self.cast_tuple(value)
    when Array
      self.cast_list(value)
    when Range, Iterator
      # TODO: Implement iterator and range trough pyobject `getitem`
      self.cast_list(value.to_a)
    when Char
      value.to_s
    when Value
      value.raw
    else
      if !value.is_a?(Type) && value.responds_to?(:raw)
        # JSON::Any & YAML::Any
        cast_value(value.raw)
      else
        value.as(Type)
      end
    end
  end

  # Casts an object with hash-like interface to `Dictionary`.
  def self.cast_hash(value) : Crinja::Type
    type_hash = Dictionary.new
    value.each do |k, v|
      type_hash[cast_value(k)] = cast_value(v)
    end
    type_hash
  end

  # Casts a `NamedTuple` to `Dictionary`, converting symbol keys to strings.
  def self.cast_named_tuple(value) : Crinja::Type
    type_hash = Dictionary.new
    value.each do |k, v|
      type_hash[k.to_s] = cast_value(v)
    end
    type_hash
  end

  # Casts an object with iterable interface to `Array(Crinja::Type)`.
  def self.cast_list(array) : Crinja::Type
    array.map do |item|
      cast_value(item).as(Crinja::Type)
    end
  end

  # Casts a tuple to `PyTuple`.
  def self.cast_tuple(tuple) : Crinja::Type
    PyTuple.from(tuple)
  end
end
