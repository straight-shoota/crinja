class Crinja::Operator
  class IntDivide < Operator
    include Binary
    name "//"

    def value(env : Crinja, op1, op2)
      if op1.number? && op2.number?
        op1.to_i // op2.to_i
      else
        raise Arguments::Error.new(self, "Both operators need to be numeric")
      end
    end
  end
end
