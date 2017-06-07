Crinja.function(:cycler) do
  Crinja::Cycler.new(arguments.varargs)
end

class Crinja::Cycler
  include Iterator(Type)
  include PyObject

  getattr :next, :rewind, :reset, :current

  def initialize(@values : Array(Value))
    @index = 0
  end

  def current
    @values[@index].raw
  end

  def next
    value = current
    @index += 1
    @index %= @values.size
    value
  end

  def rewind
    @index = 0
  end

  def reset
    rewind
  end

  def __call__(method)
    case method
    when "next"
      ->(arguments : Arguments) { self.next.as(Type) }
    end
  end
end
