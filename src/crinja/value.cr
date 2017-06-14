require "./util/py_object"
require "./util/undefined"
require "./util/safe_string"
require "./lib/callable"

module Crinja
  # :nodoc:
  alias TypeNumber = Float64 | Int64 | Int32
  # :nodoc:
  alias TypeValue = TypeNumber | String | Bool | Time | PyObject | Undefined | Crinja::Callable | SafeString | Nil
  # :nodoc:
  alias TypeContainer = Hash(Type, Type) | Array(Type) | Iterator(Type)

  alias Type = TypeValue | TypeContainer
end

# was intended to be a struct, but that crashes iterator

# Value is a value object inside the Crinja runtime.
class Crinja::Value
  include Enumerable(self)
  include Iterable(self)
  include Comparable(self)

  getter raw : Type

  def initialize(@raw)
  end

  # Assumes the underlying value responds to `size` and returns
  # its size.
  def size : Int
    if (object = @raw).responds_to?(:size)
      object.size
    else
      raise TypeError.new(self, "#{object.class} does not respond to #size")
    end
  end

  # Assumes the underlying value is an `Indexable` or `String` returns the element
  # at the given index.
  # Raises if the underlying value is not an `Indexable` or `String`.
  def [](index : Int) : Value
    case object = @raw
    when Indexable
      Value.new object[index]
    when String
      Value.new object[index].to_s
    else
      raise TypeError.new(self, "expected Array for #[](index : Int), not #{object.class}")
    end
  end

  # Assumes the underlying value is an `Indexable` or `String` and returns the element
  # at the given index, or `nil` if out of bounds.
  # Raises if the underlying value is not an `Indexable` or `String`.
  def []?(index : Int) : Value?
    case object = @raw
    when Indexable
      value = object[index]?
      value ? Value.new(value) : nil
    when String, SafeString
      value = object[index]?
      value ? Value.new(value.to_s) : nil
    else
      raise TypeError.new(self, "expected Array for #[]?(index : Int), not #{object.class}")
    end
  end

  # Assumes the underlying value has an hash-like accessor and returns the element
  # with the given key.
  # Raises if the underlying value is not hash-like.
  def [](key : String) : Value
    Value.new Environment.resolve_with_hash_accessor(key, @raw)
  end

  # Assumes the underlying value has an hash-like accessor returns the element
  # with the given key, or `nil` if the key is not present.
  # Raises if the underlying value is not hash-like.
  def []?(key : String) : Value?
    Value.new Environment.resolve_with_hash_accessor(key, @raw)
  end

  # Assumes the underlying value is an `Iterable`, `Hash` or `String` and returns the first
  # item in the list or the first character of the string.
  def first
    case object = @raw
    when Hash(Type, Type)
      Value.new(PyTuple.new(object.first_key, object.first_value))
    when Iterable
      Value.new object.first
    when String
      Value.new object[0, 1]
    else
      raise TypeError.new(self, "expected Iterable, Hash or String for #first, not #{object.class}")
    end
  end

  # Assumes the underlying value is a `String` or responds to `last` and returns the last
  # item in the list or the last character of the string.
  def last
    object = @raw

    if object.responds_to?(:last)
      Value.new object.last
    elsif object.is_a?(String)
      Value.new object[-1, 1]
    else
      raise TypeError.new(self, "expected Enumerable or String for #last, not #{object.class}")
    end
  end

  # Returns an iterator for the underlying value if it is an `Iterable`, `String` or `Undefined`
  # which iterates through the items as `Value`.
  def each
    case object = @raw
    when Hash
      HashValueIterator.new(object.each)
    when Iterable(Type)
      ValueIterator.new(object.each.as(Iterator(Type)))
    when String
      ValueIterator.new(object.chars.map(&.to_s.as(Type)).each)
    when Crinja::StrictUndefined
      raise TypeError.new(self, "can't iterate over undefined")
    when Crinja::Undefined
      ValueIterator.new(([] of Type).each)
    else
      raise TypeError.new(self, "#{object.class} is not iterable")
    end
  end

  # Assumes the underlying value is an `Iterable` and yields each
  # of the elements or key/values, always as `Value`.
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

  private class HashValueIterator
    include Iterator(Value)
    include IteratorWrapper

    def initialize(@iterator : Iterator(Tuple(Type, Type)))
    end

    def next
      tuple = wrapped_next

      case tuple
      when Tuple
        Value.new PyTuple.from tuple
      when stop
        stop
      else
        raise "never reach"
      end
    end
  end

  # Checks that the underlying value is `Nil`, and returns `nil`. Raises otherwise.
  def as_nil : Nil
    @raw.as(Nil)
  end

  # Checks that the underlying value is `String` or `SafeString`, and returns its value. Raises otherwise.
  def as_s
    @raw.as(String | SafeString)
  end

  # Checks that the underlying value is `String`, `SafeString` or `Nil`, and returns its value. Raises otherwise.
  def as_s?
    @raw.as(String | SafeString | Nil)
  end

  # Checks that the underlying value is `String`, and returns its value. `SafeString` is converted to
  # `String`. Raises otherwise.
  def as_s!
    if @raw.is_a?(SafeString)
      @raw.to_s
    else
      @raw.as(String)
    end
  end

  # Checks that the underlying value is `Array`, and returns its value. Raises otherwise.
  def as_a : Array(Type)
    @raw.as(Array)
  end

  # Checks that the underlying value is `Hash`, and returns its value. Raises otherwise.
  def as_h : Hash(Type, Type)
    @raw.as(Hash)
  end

  # Checks that the underlying value is a `TypeNumber`, and returns its value. Raises otherwise.
  def as_number : TypeNumber
    @raw.as(TypeNumber)
  end

  # Checks that the underlaying value is a `Time` object and retuns its value. Raises otherwise.
  def as_time
    @raw.as(Time)
  end

  # Checks that the underlaying value is a `Iterable` and retuns its value. Raises otherwise.
  def as_iterable
    @raw.as(Iterable)
  end

  # Checks that the underlaying value is a `Indexable` and retuns its value. Raises otherwise.
  def as_indexable
    @raw.as(Indexable)
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
  def to_s
    if (raw = @raw).is_a?(String)
      raw
    else
      super
    end
  end

  # Transform the value into a string representation.
  def to_string
    self.class.stringify(@raw)
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
      to_s <=> other.to_s
    elsif number? && other.number?
      as_number <=> other.as_number
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
      raise TypeError.new("can't convert #{raw.inspect} to Int32")
    end
  end

  def to_f
    raw = @raw
    if raw.responds_to?(:to_f)
      raw.to_f
    else
      raise TypeError.new("can't convert #{raw.inspect} to Float32")
    end
  end

  # Returns `true` unless this value is `false`, `0`, `nil` or `#undefined?`
  def truthy?
    self.class.truthy? @raw
  end

  # :ditto:
  def self.truthy?(raw)
    raw != false && raw != 0 && !raw.nil? && !self.undefined?(raw)
  end

  # Returns `true` if this value is a `Undefined`
  def undefined?
    self.class.undefined? @raw
  end

  # :ditto:
  def self.undefined?(raw)
    raw.is_a?(Undefined)
  end

  # Returns `true` if this value is a `Callable`
  def callable?
    @raw.is_a?(Crinja::Callable)
  end

  # Returns `true` if this value is a `TypeNumber`
  def number?
    @raw.is_a?(TypeNumber)
  end

  # Returns `true` if the value is a sequence.
  # TODO: Improve implementation based on __getitem__
  def sequence?
    @raw.is_a?(Iterable) || @raw.responds_to?(:each) || string?
  end

  # Returns `true` if the value is a list (`Array`).
  def indexable?
    @raw.is_a?(Indexable)
  end

  # Returns `true` if the value is iteraable.
  def iterable?
    @raw.is_a?(Iterable)
  end

  # Returns `true` if the value is a string.
  def string?
    @raw.is_a?(String | SafeString)
  end

  # Returns `true` if the object is a mapping (Hash or PyObject).
  def mapping?
    @raw.is_a?(Hash) || @raw.responds_to?(:getattr)
  end

  # Returns `true` if the value is a time object.
  def time?
    @raw.is_a(Time)
  end

  # Returns `true` if the value is nil.
  def none?
    @raw.nil?
  end

  # Returns true if
  def sameas?(other)
    raw = @raw
    if (raw.is_a?(Reference))
      if ((oraw = other.raw).is_a?(Reference))
        raw.same?(oraw)
      else
        false
      end
    else
      !other.raw.is_a?(Reference) && self == other
    end
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

  # Convert a `Type` to string with optional *escape*.
  def self.stringify(raw, escape = false)
    string = raw.to_s

    if escape
      SafeString.escaped(string)
    else
      string
    end
  end

  # Convert a `Type` to string with optional *escape*.
  def self.stringify(io : IO, raw, escape = false)
    io << stringify(raw, escape)
  end

  # Convert a `nil` to `"none"`.
  #
  # *escape* is ignored.
  def self.stringify(raw : Nil, escape = false)
    "none"
  end

  # Convert a `SafeString` to string.
  #
  # *escape* is ignored.
  def self.stringify(safe : SafeString, escape = false)
    safe.to_s
  end
end
