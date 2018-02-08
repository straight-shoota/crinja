class Crinja::Operator
  class Equals < Operator
    include Binary
    name "=="

    def value(env : Crinja, op1 : Value, op2 : Value)
      op1 == op2
    rescue TypeError
      op1.raw == op2.raw
    end
  end

  class NotEquals < Operator
    include Binary
    name "!="

    def value(env : Crinja, op1 : Value, op2 : Value)
      op1 != op2
    rescue TypeError
      op1.raw != op2.raw
    end
  end

  class GreaterThan < Operator
    include Binary
    name ">"

    def value(env : Crinja, op1 : Value, op2 : Value)
      op1 > op2
    end
  end

  class GreaterThanEquals < Operator
    include Binary
    name ">="

    def value(env : Crinja, op1 : Value, op2 : Value)
      op1 >= op2
    end
  end

  class LowerThan < Operator
    include Binary
    name "<"

    def value(env : Crinja, op1 : Value, op2 : Value)
      op1 < op2
    end
  end

  class LowerThanEquals < Operator
    include Binary
    name "<="

    def value(env : Crinja, op1 : Value, op2 : Value)
      op1 <= op2
    end
  end
end
