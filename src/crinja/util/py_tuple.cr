require "../value"

# Implementation of a Python Tuple
class Crinja::PyTuple
  include Comparable(PyTuple)
  include Indexable(Type)
  include PyObject

  def initialize(@data : Array(Type) = Array(Type).new)
  end

  delegate size, unsafe_at, :<=>, to_s, :==, to: @data

  def +(item : Type)
    PyTuple.from(@data, item)
  end

  def +(other : PyTuple)
    PyTuple.from(@data + other.@data)
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

  def self.from(data : Iterable(Type), *add)
    new(data.each_with_object([] of Type) do |item, arr|
      arr << item
    end.tap do |arr|
      add.each { |item| arr << item }
    end)
  end

  def self.new(*data)
    new(data.each_with_object([] of Type) do |item, arr|
      arr << item
    end)
  end
end
