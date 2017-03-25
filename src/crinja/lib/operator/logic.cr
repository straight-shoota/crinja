class Crinja::Operator
  class And < Binary
    name "and"

    def value(env : Environment, op1 : Any, op2 : Any)
      !!(op1.raw && op2.raw)
    end
  end

  class Or < Binary
    name "or"

    def value(env : Environment, op1 : Any, op2 : Any)
      !!(op1.raw || op2.raw)
    end
  end

  class Not < Unary
    name "not"

    def value(env : Environment, op : Any)
      !op.raw
    end
  end
end
