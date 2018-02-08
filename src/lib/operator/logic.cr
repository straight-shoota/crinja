class Crinja::Operator
  class And < Operator
    include Logic
    name "and"

    def value(env : Crinja, op1 : Value, &op2 : -> Value) : Value
      Value.new !!(op1.truthy? && op2.call.truthy?)
    end
  end

  class Or < Operator
    include Logic
    name "or"

    def value(env : Crinja, op1 : Value, &op2 : -> Value) : Value
      Value.new !!(op1.truthy? || op2.call.truthy?)
    end
  end

  class Not < Operator
    include Unary
    name "not"

    def value(env : Crinja, op : Value) : Value
      Value.new !op.truthy?
    end
  end
end
