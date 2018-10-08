class Crinja::Operator
  class Power < Operator
    include Binary
    name "**"

    def value(env : Crinja, op1, op2)
      if op1.number? && op2.number?
        base = op1.as_number
        power = op2.as_number
        if power < 0
          base ** power.to_f
        else
          base ** power
        end
      else
        raise Arguments::Error.new(self, "Both operators need to be numeric")
      end
    end
  end
end
