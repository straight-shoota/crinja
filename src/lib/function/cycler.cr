Crinja.function(:cycler) do
  Crinja::Function::Cycler.new(arguments.varargs).as(Iterator(Crinja::Value))
end

class Crinja::Function::Cycler
  include Iterator(Value)
  include PyObject

  getattr :next, :rewind, :reset, :current

  def initialize(@values : Array(Value))
    @index = -1
  end

  def current
    return "" if @index < 0 # .current called directly after initialization or rewind
    @values[@index].raw
  end

  def next
    @index += 1
    @index %= @values.size
    current
  end

  def rewind
    @index = -1
    ""
  end

  def reset
    rewind
  end

  def __call__(method)
    case method
    when "next"
      ->(arguments : Arguments) { self.next }
    when "reset", "rewind"
      ->(arguments : Arguments) { reset }
    end
  end
end
