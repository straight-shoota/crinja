abstract class Crinja::Operator
  include Importable

  abstract def num_operands : Int32

  macro num_operands(num_operands)
    def num_operands
      {{ num_operands }}
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
    num_operands 2

    def value(env : Environment, operands : Array(Type)) : Type
      op1 = Value.new operands[0]
      op2 = Value.new operands[1]

      value(env, op1, op2)
    end

    abstract def value(env : Environment, op1 : Value, op2 : Value) : Type
  end

  abstract class Unary < Operator
    num_operands 1

    def value(env : Environment, operands : Array(Type)) : Type
      op = Value.new operands[0]

      value(env, op)
    end

    abstract def value(env : Environment, op : Value) : Type
  end
end

require "./operator/*"
