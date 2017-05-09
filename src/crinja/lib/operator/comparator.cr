class Crinja::Operator
  class Equals < Binary
    name "=="

    def value(env : Environment, op1 : Value, op2 : Value)
      op1 == op2
    end
  end

  class NotEquals < Binary
    name "!="

    def value(env : Environment, op1 : Value, op2 : Value)
      op1 != op2
    end
  end

  abstract class Comparator < Binary
    def compare(a : Type, b : Type)
      if a.is_a?(Array(Type))
        if b.is_a?(Array(Type))
          compare_array(a, b)
        else
          raise InvalidArgumentException.new self, "Cannot compare Array(Type) with #{b.class}"
        end
      elsif a.is_a?(Bool) || b.is_a?(Bool)
        raise InvalidArgumentException.new self, "Cannot compare Bool value"
      elsif a.is_a?(Number) && b.is_a?(Number)
        a <=> b
      elsif a.is_a?(String | SafeString) || a.is_a?(String | SafeString)
        a.to_s <=> b.to_s
      else
        raise TypeError.new("cannot compare #{a.class} with #{b.class}")
      end
    end

    def compare_array(a : Array(Type), b : Array(Type))
      # reimplement Array#<=>
      min_size = Math.min(a.size, b.size)
      0.upto(min_size - 1) do |i|
        n = compare(a[i], b[i])
        return n if n != 0
      end
      a.size <=> b.size
    end
  end

  class GreaterThan < Comparator
    name ">"

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) > 0
    end
  end

  class GreaterThanEquals < Comparator
    name ">="

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) >= 0
    end
  end

  class LowerThan < Comparator
    name "<"

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) < 0
    end
  end

  class LowerThanEquals < Comparator
    name "<="

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) <= 0
    end
  end
end
