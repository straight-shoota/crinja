require "./value"

# Implementation of a Python Tuple
class Crinja::Tuple
  include Comparable(Crinja::Tuple)
  include Indexable(Value)
  include Object

  def initialize(@data : Array(Value) = Array(Value).new)
  end

  delegate size, unsafe_at, :<=>, to_s, :==, to: @data

  def +(item : Value)
    Crinja::Tuple.from(@data, item)
  end

  def +(other : Crinja::Tuple)
    Crinja::Tuple.from(@data + other.@data)
  end

  def ==(other : Crinja::Tuple)
    self == other.@data
  end

  def to_s(io)
    io << "(("
    join ", ", io, &.inspect(io)
    io << "))"
  end

  # :nodoc:
  def inspect(io : IO)
    to_s io
  end

  def pretty_print(pp) : Nil
    pp.list("((", self, "))")
  end

  def self.from(data : Iterable, *add)
    new(data.each_with_object([] of Value) do |item, arr|
      arr << Value.new item
    end.tap do |arr|
      add.each { |item| arr << Value.new item }
    end)
  end

  def self.new(*data)
    new(data.each_with_object([] of Value) do |item, arr|
      arr << Value.new item
    end)
  end
end
