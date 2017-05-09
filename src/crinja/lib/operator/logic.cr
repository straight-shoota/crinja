class Crinja::Operator
  class And < Binary
    name "and"

    def value(env : Environment, op1 : Value, op2 : Value)
      !!(op1.truthy? && op2.truthy?)
    end
  end

  class Or < Binary
    name "or"

    def value(env : Environment, op1 : Value, op2 : Value)
      !!(op1.truthy? || op2.truthy?)
    end
  end

  class Not < Unary
    name "not"

    def value(env : Environment, op : Value)
      !op.truthy?
    end
  end
end
