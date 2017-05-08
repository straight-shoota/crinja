class Crinja::Operator
  class Power < Binary
    name "**"

    def value(env : Environment, op1, op2)
      if op1.number? && op2.number?
        base = op1.as_number
        power = op2.as_number
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
