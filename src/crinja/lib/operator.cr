abstract class Crinja::Operator
  abstract def num_operands : Int32

  macro name(name, end_tag = nil)
    def name
      {{ name }}
    end

    def end_tag : String?
      {{ end_tag }}
    end
  end

  abstract def value(env : Environment, operands : Array(Type)) : Type

  def inspect(io : IO)
    to_s(io)
  end

  def to_s(io : IO)
    io << name << "(" << num_operands << ")"
  end

  def unary?
    num_operands == 1
  end

  def binary?
    num_operands == 2
  end

  def ternary?
    num_operands == 3
  end

  class Library < FeatureLibrary(Operator)
    register_default [Plus, Minus, Divide, IntDivide, Modulo, Multiply, Power,
                      Tilde,
                      Equals, NotEquals, GreaterThan, GreaterThanEquals, LowerThan, LowerThanEquals,
                      And, Or, Not]
  end

  abstract class Binary < Operator
    def num_operands
      2
    end

    def value(env : Environment, operands : Array(Type)) : Type
      op1 = Value.new operands[0]
      op2 = Value.new operands[1]

      value(env, op1, op2)
    end

    abstract def value(env : Environment, op1 : Value, op2 : Value) : Type
  end

  abstract class Unary < Operator
    def num_operands
      1
    end

    def value(env : Environment, operands : Array(Type)) : Type
      op = Value.new operands[0]

      value(env, op)
    end

    abstract def value(env : Environment, op : Value) : Type
  end
end

require "./operator/*"
