class Crinja::Operator
  class Minus < Binary
    name "-"

    def value(env : Environment, op1, op2)
      if op1.raw.is_a?(Float64 | Int32) && op2.raw.is_a?(Float64 | Int32)
        op1.raw.as(Float64 | Int32) - op2.raw.as(Float64 | Int32)
      else
        raise InvalidArgumentException.new(self, "Both operators need to be numeric")
      end
    end
  end
end
