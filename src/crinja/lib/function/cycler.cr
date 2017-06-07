Crinja.function(:cycler) do
  Crinja::Cycler.new(arguments.varargs)
end

class Crinja::Cycler
  include Iterator(Type)
  include PyObject

  getattr :next, :rewind, :reset, :current

  def initialize(@values : Array(Value))
    @index = -1
  end

  def current
    return nil if @index < 0 # .current called directly after initialization or rewind
    @values[@index].raw
  end

  def next
    @index += 1
    @index %= @values.size
    current
  end

  def rewind
    @index = -1
    nil
  end

  def reset
    rewind
  end

  def __call__(method)
    case method
    when "next"
      ->(arguments : Arguments) { self.next.as(Type) }
    when "reset", "rewind"
      ->(arguments : Arguments) { reset.as(Type) }
    end
  end
end
