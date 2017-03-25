class Crinja::Operator
  class Power < Binary
    name "**"

    def value(env : Environment, op1, op2)
      if op1.raw.is_a?(Float64 | Int32) && op2.raw.is_a?(Float64 | Int32)
        base = op1.raw.as(Float64 | Int32)
        power = op2.raw.as(Float64 | Int32)
        if power < 0
          base ** power.to_f
        else
          base ** power
        end
      else
        raise InvalidArgumentException.new(self, "Both operators need to be numeric")
      end
    end
  end
end
