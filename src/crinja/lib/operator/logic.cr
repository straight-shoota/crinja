class Crinja::Operator
  class And < Operator
    include Logic
    name "and"

    def value(env : Environment, op1 : Value, &op2 : -> Value) : Type
      !!(op1.truthy? && op2.call.truthy?)
    end
  end

  class Or < Operator
    include Logic
    name "or"

    def value(env : Environment, op1 : Value, &op2 : -> Value) : Type
      !!(op1.truthy? || op2.call.truthy?)
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
