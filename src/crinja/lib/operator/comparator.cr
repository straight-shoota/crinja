class Crinja::Operator
  module Comparator
    extend self

    def compare(a : Type, b : Type)
      if a.is_a?(Array(Type))
        if b.is_a?(Array(Type))
          compare_array(a, b)
        else
          raise TypeError.new "Cannot compare Array(Type) with #{b.class}"
        end
      elsif a.is_a?(Bool) || b.is_a?(Bool)
        raise TypeError.new "Cannot compare Bool value"
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

  class Equals < Operator
    include Binary
    name "=="
    include Comparator

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) == 0
    rescue TypeError
      op1.raw == op2.raw
    end
  end

  class NotEquals < Operator
    include Binary
    name "!="
    include Comparator

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) != 0
    rescue TypeError
      op1.raw != op2.raw
    end
  end

  class GreaterThan < Operator
    include Binary
    name ">"
    include Comparator

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) > 0
    end
  end

  class GreaterThanEquals < Operator
    include Binary
    name ">="
    include Comparator

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) >= 0
    end
  end

  class LowerThan < Operator
    include Binary
    name "<"
    include Comparator

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) < 0
    end
  end

  class LowerThanEquals < Operator
    include Binary
    name "<="
    include Comparator

    def value(env : Environment, op1 : Value, op2 : Value)
      compare(op1.raw, op2.raw) <= 0
    end
  end
end
