class Crinja::Operator
  class Plus < Binary
    name "+"

    def value(env : Environment, op1, op2)
      if op1.number? && op2.number?
        op1.as_number + op2.as_number
      elsif op1.raw.is_a?(Array(Type))
        adding = op2.raw
        if adding.is_a?(Array(Type))
          op1.as_a + adding
        else
          op1.as_a << adding
        end
      else
        op1.to_s + op2.to_s
      end
    end
  end
end
