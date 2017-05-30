# The default undefined type.
class Crinja::Undefined
  getter name

  def initialize(@name = "")
  end

  def to_s(io)
  end
end

# An undefined that raises an `UndefinedError` if it is compared or printed.
class Crinja::StrictUndefined < Crinja::Undefined
  def ==(other)
    fail
  end

  def <=>(other)
    fail
  end

  def to_s(io)
    fail
  end

  private def fail
    raise UndefinedError.new(self.name)
  end
end
