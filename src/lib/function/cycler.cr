Crinja.function(:cycler) do
  Crinja::Function::Cycler.new(arguments.varargs).as(Iterator(Crinja::Value))
end

class Crinja::Function::Cycler
  include Iterator(Value)
  include Crinja::Object::Auto

  def initialize(@values : Array(Value))
    @index = -1
  end

  @[Crinja::Attribute]
  def current
    return Value::UNDEFINED if @index < 0 # .current called directly after initialization or rewind
    @values[@index]
  end

  @[Crinja::Attribute]
  def next : Crinja::Value | ::Iterator::Stop
    @index += 1
    @index %= @values.size
    current
  end

  @[Crinja::Attribute]
  def rewind
    @index = -1
    ""
  end

  @[Crinja::Attribute]
  def reset
    rewind
  end

  def crinja_call(method)
    case method
    when "next"
      ->(arguments : Arguments) { self.next }
    when "reset", "rewind"
      ->(arguments : Arguments) { reset }
    else
      nil
    end
  end
end
