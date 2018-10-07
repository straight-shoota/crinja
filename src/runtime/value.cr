require "./py_object"
require "./undefined"
require "./safe_string"
require "./callable"

class Crinja
  # :nodoc:
  alias Number = Float64 | Int64 | Int32
  # :nodoc:
  alias Raw = Number | String | Bool | Time | PyObject | Undefined | Callable | Callable::Proc | SafeString | Dictionary | Array(Value) | Iterator(Value) | Nil

  alias Dictionary = Hash(Value, Value)

  # FIXME
  # class Dictionary < Hash(Value, Value)
  #   def []=(key, value)
  #     self[Value.new(key)] = Value.new value
  #   end

  #   def [](key)
  #     self[Value.new(key)]
  #   end
  # end

  # Casts an object with hash-like interface to `Dictionary`.
  def self.dictionary(object) : Dictionary
    Dictionary.new.tap do |dict|
      object.each do |key, value|
        dict[Value.new(key)] = Value.new value
      end
    end
  end

  alias Variables = Hash(String, Value)

  # FIXME
  # class Variables < Hash(String, Value)
  #   def []=(key : String, value)
  #     self[key] = Value.new value
  #   end
  # end

  # Casts an object with hash-like interface to `Variables`, which can be
  # used for name lookup.
  def self.variables(object) : Variables
    Variables.new.tap do |variables|
      object.each do |k, v|
        variables[k.to_s] = Value.new v
      end
    end
  end

  def self.value(value) : Value
    # This methods cast datastructures with Crystal types like `Array(String)`
    # to Crinja::Value.
    case value
    when Hash
      Value.new Crinja.dictionary(value)
    when NamedTuple
      dict = Dictionary.new
      value.each do |k, v|
        dict[Value.new k.to_s] = value(v)
      end
      Value.new dict
    when ::Tuple
      Value.new Crinja::Tuple.from(value)
    when Array
      array = value.map do |item|
        value(item).as(Value)
      end
      Value.new array
    when Range
      # TODO: Implement range trough pyobject `getitem`
      Value.new value.to_a
    when Iterator(Value)
      Value.new value
    when Iterator
      Value.new Value::Iterator.new(value)
    when Char
      Value.new value.to_s
    when Value
      value
    when Raw
      Value.new value
    when .responds_to? :raw
      # match JSON::Any | YAML::Any without including json and yaml
      value value.raw
    else
      raise "type error: can't wrap #{value.class} in Crinja::Value"
    end
  end
end

# `Value` represents an object inside the Crinja runtime.
#
# It wraps a Crystal value in `#raw` and defines methods to access
# properties of the wrapped value while being agnostic about the
# actual type of the wrapped raw value.
struct Crinja::Value
  include Enumerable(self)
  include Iterable(self)
  include Comparable(self)

  getter raw : Raw

  def self.new(value : self) : self
    value
  end

  def self.new(value) : self
    Crinja.value(value)
  end

  def initialize(@raw : Raw)
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
      Value.new(Crinja::Tuple.new(object.first_key, object.first_value))
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
  def raw_each : ::Iterator
    case object = @raw
    when Hash
      HashTupleIterator.new(object.each)
    when Iterable(Value)
      RawIterator.new(object.each)
    when Iterable
      object.each
    when ::Iterator(Value)
      RawIterator.new(object)
    when ::Iterator
      object
    when String
      object.each_char.map { |char| char.to_s }
    when StrictUndefined
      raise TypeError.new(self, "can't iterate over undefined")
    when Undefined
      ([] of Nil).each
    else
      raise TypeError.new(self, "#{object.class} is not iterable")
    end
  end

  # Returns an iterator for the underlying value if it is an `Iterable`, `String` or `Undefined`
  # which iterates through the items as `Value`.
  def each
    Iterator.new(raw_each)
  end

  # Assumes the underlying value is an `Iterable` and yields each
  # of the elements or key/values, always as `Value`.
  def raw_each
    case object = @raw
    when Hash
      object.each { |key, value| yield Crinja::Tuple.from({key, value}) }
    when Iterable(Value), ::Iterator(Value)
      object.each { |value| yield value.as(Value).raw }
    when Iterable, ::Iterator
      object.each { |value| yield value }
    when String
      object.each_char { |char| yield char.to_s }
    when StrictUndefined
      raise TypeError.new(self, "can't iterate over undefined")
    when Undefined
    else
      raise TypeError.new(self, "#{object.class} is not iterable")
    end
  end

  # Assumes the underlying value is an `Iterable` and yields each
  # of the elements or key/values, always as `Value`.
  def each
    raw_each do |raw|
      yield Value.new raw
    end
  end

  # :nodoc:
  class RawIterator
    include ::Iterator(Raw)
    include IteratorWrapper

    def initialize(@iterator : ::Iterator(Value))
    end

    def next
      value = wrapped_next

      case value
      when Value
        value.raw
      when stop
        stop
      else
        # TODO: should never be reached, maybe raise?
        Crinja::UNDEFINED
      end
    end
  end

  class Iterator(T)
    include ::Iterator(Value)
    include IteratorWrapper

    @iterator : T

    def initialize(@iterator : T)
    end

    def ==(other : Iterator)
      @iterator == other.@iterator
    end

    def next : Value | Iterator::Stop
      value = wrapped_next

      case value
      when Iterator::Stop
        stop
      else
        Value.new(value)
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
  def as_a : Array(Value)
    raise_undefined!
    @raw.as(Array)
  end

  # Checks that the underlying value is `Hash`, and returns its value. Raises otherwise.
  def as_h : Dictionary
    raise_undefined!
    @raw.as(Hash)
  end

  # Checks that the underlying value is a `Crinja::Number`, and returns its value. Raises otherwise.
  def as_number : Number
    raise_undefined!
    @raw.as(Number)
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

  # Checks that the underlaying value is a `Callable | Callable::Proc` and retuns its value. Raises otherwise.
  def as_callable
    raise_undefined!
    @raw.as(Callable | Callable::Proc)
  end

  def as_undefined
    @raw.as(Undefined)
  end

  private def raise_undefined!
    if (undefined = @raw).is_a?(Undefined)
      raise UndefinedError.new(undefined)
    end
  end

  def to_a
    if (raw = @raw).is_a?(Array)
      return raw
    end

    array = [] of Value
    each do |item|
      array << item
    end
    array
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

  def to_json(builder : JSON::Builder)
    Crinja::JsonBuilder.to_json(builder, self)
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

  def <=>(other : Value)
    compare raw, other.raw
  end

  private def compare(a, b)
    if a.is_a?(Array)
      if b.is_a?(Array)
        compare_array(a, b)
      else
        raise TypeError.new "Cannot compare Array with #{b.class}"
      end
    elsif a.is_a?(Bool) || b.is_a?(Bool)
      raise TypeError.new "Cannot compare Bool value"
    elsif a.is_a?(Number) && b.is_a?(Number)
      a <=> b
    elsif a.is_a?(String | SafeString) || a.is_a?(String | SafeString)
      a.to_s <=> b.to_s
    else
      raise TypeError.new("cannot compare #{a.class} with #{b.class}")
    end
  end

  private def compare_array(a : Array, b : Array)
    # reimplement Array#<=>
    min_size = Math.min(a.size, b.size)
    0.upto(min_size - 1) do |i|
      n = a[i] <=> b[i]
      return n if n != 0
    end
    a.size <=> b.size
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
    !(@raw == false || @raw == 0 || @raw.nil? || undefined?)
  end

  # Returns `true` if this value is a `Undefined`
  def undefined?
    @raw.is_a?(Undefined)
  end

  # Returns `true` if this value is a `Callable`
  def callable?
    @raw.is_a?(Callable | Callable::Proc)
  end

  # Returns `true` if this value is a `Number`
  def number?
    @raw.is_a?(Number)
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

  UNDEFINED = new(Undefined.new)
end

require "./tuple"

struct Crinja::Value
  private class HashTupleIterator
    include ::Iterator(Crinja::Tuple)
    include IteratorWrapper

    def initialize(@iterator : ::Iterator(::Tuple(Value, Value)))
    end

    def next
      tuple = wrapped_next

      if tuple.is_a?(::Tuple)
        Crinja::Tuple.from tuple
      else
        stop
      end
    end
  end
end
