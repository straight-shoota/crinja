require "./util/py_object"
require "./util/undefined"
require "./lib/callable"

module Crinja
  # :nodoc:
  alias TypeValue = String | Float64 | Int64 | Int32 | Bool | PyObject | Undefined | Crinja::Callable | SafeString | Nil
  # :nodoc:
  alias TypeContainer = Hash(Type, Type) | Array(Type) | Tuple(Type, Type) # |Array(Tuple(Type, Type))
  alias Type = TypeValue | TypeContainer
end

# was intended to be a struct, but that crashes iterator

# Value is a value object inside the Crinja runtime.
class Crinja::Value
  include Enumerable(self)
  include Iterable(self)

  getter raw : Type

  def initialize(@raw)
  end

  # Assumes the underlying value is an `Array` or `Hash` and returns
  # its size.
  # Raises if the underlying value is not an `Array` or `Hash`.
  def size : Int
    case object = @raw
    when Array
      object.size
    when Hash
      object.size
    when String
      object.size
    when Undefined
      0
    else
      raise "expected Array or Hash for #size, not #{object.class}"
    end
  end

  # Assumes the underlying value is an Array and returns the element
  # at the given index.
  # Raises if the underlying value is not an Array.
  def [](index : Int) : Value
    case object = @raw
    when Array
      Value.new object[index]
    else
      raise "expected Array for #[](index : Int), not #{object.class}"
    end
  end

  # Assumes the underlying value is an Array and returns the element
  # at the given index, or `nil` if out of bounds.
  # Raises if the underlying value is not an Array.
  def []?(index : Int) : Value?
    case object = @raw
    when Array
      value = object[index]?
      value ? Value.new(value) : nil
    else
      raise "expected Array for #[]?(index : Int), not #{object.class}"
    end
  end

  # Assumes the underlying value is a Hash and returns the element
  # with the given key.
  # Raises if the underlying value is not a Hash.
  def [](key : String) : Value
    case object = @raw
    when Hash
      Value.new object[key]
    else
      raise "expected Hash for #[](key : String), not #{object.class}"
    end
  end

  # Assumes the underlying value is a Hash and returns the element
  # with the given key, or `nil` if the key is not present.
  # Raises if the underlying value is not a Hash.
  def []?(key : String) : Value?
    case object = @raw
    when Hash
      value = object[key]?
      value ? Value.new(value) : nil
    else
      raise "expected Hash for #[]?(key : String), not #{object.class}"
    end
  end

  # Assumes the underlying value is an `Array` or `Hash` and yields each
  # of the elements or key/values, always as `YAML::Value`.
  # Raises if the underlying value is not an `Array` or `Hash`.
  def __each
    case object = @raw
    when Array
      object.each do |elem|
        yield Value.new(elem), Value.new(nil)
      end
    when Hash
      object.each do |key, value|
        yield Value.new(key), Value.new(value)
      end
    when Crinja::Undefined
    else
      raise TypeError.new("#{object.class} is not iterable")
    end
  end

  def each
    case object = @raw
    when Iterable(Type)
      ValueIterator.new(object.each.as(Iterator(Type)))
    when Crinja::Undefined
      ValueIterator.new
    when String
      ValueIterator.new(object.chars.map(&.to_s.as(Type)).each)
    else
      raise TypeError.new("#{object.class} is not iterable")
    end
  end

  def each
    each.each do |a|
      yield a
    end
  end

  private class ValueIterator
    include Iterator(Value)
    include IteratorWrapper

    def initialize(@iterator : Iterator(Type) = ([] of Type).each)
    end

    def next
      value = wrapped_next

      case value
      when Value
        value
      when Type
        Value.new value
      when stop
        stop
      else
        # TODO: should never be reached, maybe raise?
        Value.undefined
      end
    end
  end

  # Checks that the underlying value is `Nil`, and returns `nil`. Raises otherwise.
  def as_nil : Nil
    @raw.as(Nil)
  end

  # Checks that the underlying value is `String`, and returns its value. Raises otherwise.
  def as_s : String
    @raw.as(String)
  end

  # Checks that the underlying value is `Array`, and returns its value. Raises otherwise.
  def as_a : Array(Type)
    @raw.as(Array)
  end

  # Checks that the underlying value is `Hash`, and returns its value. Raises otherwise.
  def as_h : Hash(Type, Type)
    @raw.as(Hash)
  end

  # Checks that the underlying value is a `Int32 | Int64 | Float64`, and returns its value. Raises otherwise.
  def as_number : Int32 | Int64 | Float64
    @raw.as(Int32 | Int64 | Float64)
  end

  # :nodoc:
  def inspect(io)
    @raw.inspect(io)
  end

  # :nodoc:
  def to_s(io)
    @raw.to_s(io)
  end

  # :nodoc:
  def pretty_print(pp)
    @raw.pretty_print(pp)
  end

  # Returns `true` if both `self` and *other*'s raw object are equal.
  def ==(other : Value)
    @raw == other.raw
  end

  # Returns `true` if the raw object is equal to *other*.
  def ==(other)
    @raw == other
  end

  # Compares this value to *other*.
  #
  # TODO: Enable proper comparison.
  def <=>(other : Value)
    thisraw = @raw
    otherraw = other.raw

    if thisraw.is_a?(String | SafeString) || otherraw.is_a?(String | SafeString)
      #  thisraw.to_s <=> otherraw.to_s
    elsif number? && other.number?
      #  thisraw <=> otherraw
      # elsif thisraw.is_a?(Array) && otherraw.is_a?(Array)
      #  thisraw <=> otherraw
    else
      0
    end
    0
  end

  # :nodoc:
  def hash
    raw.hash
  end

  def to_i
    raw = @raw
    if raw.responds_to?(:to_i)
      raw.to_i
    else
      raw.to_s.to_i
    end
  end

  def to_f
    raw = @raw
    if raw.responds_to?(:to_f)
      raw.to_f
    else
      raw.to_s.to_f
    end
  end

  # Returns `true` unless this value is `false`, `0`, `nil` or `#undefined?`
  def truthy?
    @raw != false && @raw != 0 && !@raw.nil? && !undefined?
  end

  # Returns `true` if this value is a `Undefined`
  def undefined?
    @raw.is_a?(Undefined)
  end

  # Returns `true` if this value is a `Callable`
  def callable?
    @raw.is_a?(Callable)
  end

  # Returns `true` if this value is a `Int32 | Int64 | Float64`
  def number?
    @raw.is_a?(Int32 | Int64 | Float64)
  end

  # Returns an array wrapping an instance of `Undefined`
  def self.undefined
    UNDEFINED
  end

  TRUE      = new(true)
  FALSE     = new(false)
  UNDEFINED = new(Undefined.new)

  # Returns a value representing boolean values `true` or `false`.
  def self.bool(bool)
    if bool
      TRUE
    else
      FALSE
    end
  end
end
