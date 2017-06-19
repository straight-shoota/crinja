class Crinja::Operator
  class And < Operator
    include Binary
    name "and"

    def value(env : Environment, op1 : Value, op2 : Value)
      !!(op1.truthy? && op2.truthy?)
    end
  end

  class Or < Operator
    include Binary
    name "or"

    def value(env : Environment, op1 : Value, op2 : Value)
      !!(op1.truthy? || op2.truthy?)
    end
  end

  class Not < Operator
    include Unary
    name "not"

    def value(env : Environment, op : Value)
      !op.truthy?
    end
  end
end
