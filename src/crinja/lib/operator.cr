abstract class Crinja::Operator
  macro name(name, end_tag = nil)
    def name
      {{ name }}
    end

    def end_tag : String?
      {{ end_tag }}
    end
  end

  def inspect(io : IO)
    to_s(io)
  end

  def to_s(io : IO)
    io << "operator[" << name << "]"
  end

  def unary?
    false
  end

  def binary?
    false
  end

  def ternary?
    false
  end

  class Library < FeatureLibrary(Operator)
    register_default [Plus, Minus, Divide, IntDivide, Modulo, Multiply, Power,
                      Tilde,
                      Equals, NotEquals, GreaterThan, GreaterThanEquals, LowerThan, LowerThanEquals,
                      And, Or, Not]
  end

  module Binary
    def binary?
      true
    end

    abstract def value(env : Environment, op1 : Value, op2 : Value) : Type
  end

  module Unary
    def unary?
      true
    end

    abstract def value(env : Environment, op : Value) : Type
  end
end

require "./operator/*"
