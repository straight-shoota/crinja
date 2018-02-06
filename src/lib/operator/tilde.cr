class Crinja::Operator
  class Tilde < Operator
    include Binary
    name "~"

    def value(env : Crinja, op1, op2)
      op1.to_s + op2.to_s
    end
  end
end
