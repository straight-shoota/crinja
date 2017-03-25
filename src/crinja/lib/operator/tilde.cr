class Crinja::Operator
  class Tilde < Binary
    name "~"

    def value(env : Environment, op1, op2)
      op1.to_s + op2.to_s
    end
  end
end
