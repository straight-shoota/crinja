class Crinja
  UNDEFINED = Undefined.new("UNDEFINED")

  # The default undefined type.
  class Undefined
    property name

    def initialize(@name = "")
    end

    def to_s(io)
    end

    def_equals_and_hash @name

    def to_json(json : JSON::Builder)
      json.null
    end

    def size
      0
    end
  end

  # An undefined that raises an `UndefinedError` if it is compared or printed.
  class StrictUndefined < Undefined
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
end
