class Crinja::Operator
  class Multiply < Operator
    include Binary
    name "*"

    def value(env : Crinja, op1, op2)
      if op1.number? && op2.number?
        op1.as_number * op2.as_number
      elsif op1.raw.is_a?(String) && op2.raw.is_a?(Float64 | Int32)
        op1.raw.as(String) * op2.to_i
      else
        raise Arguments::Error.new(self, "Both operators need to be numeric")
      end
    end
  end
end
