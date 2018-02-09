require "./type"
require "./py_object"
require "./undefined"
require "./safe_string"
require "./callable"

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
      raise TypeError.new(self, "expected Indexable for #[]?(index : Int), not #{object.class}")
    end
  end

  # Assumes the underlying value has an hash-like accessor and returns the element
  # with the given key.
  # Raises if the underlying value is not hash-like.
  def [](key : String) : Value
    Value.new Resolver.resolve_attribute(key, @raw)
  end

  # Assumes the underlying value has an hash-like accessor returns the element
  # with the given key, or `nil` if the key is not present.
  # Raises if the underlying value is not hash-like.
  def []?(key : String) : Value?
    Value.new Resolver.resolve_attribute(key, @raw)
  end

  # Assumes the underlying value is an `Iterable`, `Hash` or `String` and returns the first
  # item in the list or the first character of the string.
  def first
    case object = @raw
    when Dictionary
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
    ValueIterator.new raw_each
  end

  # Assumes the underlying value is an `Iterable` and yields each
  # of the elements or key/values, always as `Value`.
  def each
    each.each do |a|
      yield a
    end
  end

  # Returns an iterator for the underlying value if it is an `Iterable`, `String` or `Undefined`
  # which iterates through the items as `Type`.
  def raw_each : Iterator(Type)
    case object = @raw
    when Hash
      HashTupleIterator.new(object.each)
    when Iterable(Type)
      object.each.as(Iterator(Type))
    when Iterator(Type)
      object
    when String
      object.chars.map(&.to_s.as(Type)).each
    when StrictUndefined
      raise TypeError.new(self, "can't iterate over undefined")
    when Undefined
      ([] of Type).each
    else
      raise TypeError.new(self, "#{object.class} is not iterable")
    end
  end

  # Assumes the underlying value is an `Iterable` and yields each
  # of the elements or key/values, always as `Type`.
  def raw_each
    raw_each.each do |a|
      yield a
    end
  end

  private class ValueIterator
    include Iterator(Value)
    include IteratorWrapper

    def initialize(@iterator : Iterator(Type))
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

  private class HashTupleIterator
    include Iterator(Type)
    include IteratorWrapper

    def initialize(@iterator : Iterator(Tuple(Type, Type)))
    end

    def next
      tuple = wrapped_next

      if tuple.is_a?(Tuple)
        PyTuple.from tuple
      else
        stop
      end
    end
  end

  # Checks that the underlying value is `Nil`, and returns `nil`. Raises otherwise.
  def as_nil : Nil
    raise_undefined!
    @raw.as(Nil)
  end

  # Checks that the underlying value is `String` or `SafeString`, and returns its value. Raises otherwise.
  def as_s
    raise_undefined!
    @raw.as(String | SafeString)
  end

  # Checks that the underlying value is `String`, `SafeString` or `Nil`, and returns its value. Raises otherwise.
  def as_s?
    raise_undefined!
    @raw.as(String | SafeString | Nil)
  end

  # Checks that the underlying value is `String`, and returns its value. `SafeString` is converted to
  # `String`. Raises otherwise.
  def as_s!
    raise_undefined!
    if @raw.is_a?(SafeString)
      @raw.to_s
    else
      @raw.as(String)
    end
  end

  # Checks that the underlying value is `Array`, and returns its value. Raises otherwise.
  def as_a : Array(Type)
    raise_undefined!
    @raw.as(Array)
  end

  # Checks that the underlying value is `Hash`, and returns its value. Raises otherwise.
  def as_h : Dictionary
    raise_undefined!
    @raw.as(Hash)
  end

  # Checks that the underlying value is a `TypeNumber`, and returns its value. Raises otherwise.
  def as_number : TypeNumber
    raise_undefined!
    @raw.as(TypeNumber)
  end

  # Checks that the underlaying value is a `Time` object and retuns its value. Raises otherwise.
  def as_time
    raise_undefined!
    @raw.as(Time)
  end

  # Checks that the underlaying value is a `Iterable` and retuns its value. Raises otherwise.
  def as_iterable
    raise_undefined!
    @raw.as(Iterable)
  end

  # Checks that the underlaying value is a `Indexable` and retuns its value. Raises otherwise.
  def as_indexable
    raise_undefined!
    @raw.as(Indexable)
  end

  private def raise_undefined!
    if (undefined = @raw).is_a?(Undefined)
      raise UndefinedError.new(undefined)
    end
  end

  # :nodoc:
  def inspect(io)
    io << "Crinja::Value<"
    @raw.inspect(io)
    io << ">"
  end

  def pretty_print(pp : Crinja::PrettyPrint)
    @raw.pretty_print(pp)
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
    raise_undefined!
    Finalizer.stringify(@raw)
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
    otherraw = other.raw

    if @raw.is_a?(String | SafeString) || otherraw.is_a?(String | SafeString)
      as_s! <=> other.as_s!
    elsif number? && other.number?
      as_number <=> other.as_number
      # elsif thisraw.is_a?(Array) && otherraw.is_a?(Array)
      #  thisraw <=> otherraw
    else
      raise TypeError.new("cannot compare #{@raw.class} with #{otherraw.class}")
    end
  end

  # :nodoc:
  def hash
    raw.hash
  end

  def to_i
    raise_undefined!
    raw = @raw
    if raw.responds_to?(:to_i)
      raw.to_i
    else
      raise TypeError.new("can't convert #{raw.inspect} to Int32")
    end
  end

  def to_f
    raise_undefined!
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
    @raw.is_a?(Callable | Callable::Proc)
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
end
