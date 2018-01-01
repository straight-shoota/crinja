class Crinja::Operator
  class Minus < Operator
    include Binary
    include Unary
    name "-"

    def value(env, op1, op2)
      if op1.number? && op2.number?
        op1.as_number - op2.as_number
      else
        raise Callable::ArgumentError.new(self, "Both operators need to be numeric")
      end
    end

    def value(env, op)
      if op.number?
        op.as_number * -1
      else
        raise Callable::ArgumentError.new(self, "Operators needs to be numeric")
      end
    end
  end
end
