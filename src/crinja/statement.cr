module Crinja
  # Statement nodes return a value
  abstract class Statement
    getter token

    property parent : ParentStatement?

    alias Token = Lexer::Token

    def initialize(@token : Token = Token.new)
    end

    abstract def evaluate(env : Environment) : Type

    def value(env : Environment) : Value
      Value.new evaluate(env)
    end

    def root
      parent.not_nil!.root
    end

    def template
      root_node.try(&.template)
    end

    def root_node
      root.root_node
    end

    def statement_name
      {{ @type.stringify }}.rpartition("::").last.downcase
    end

    def to_s(io : IO)
      io << statement_name
    end

    def accept(visitor : Visitor)
      visitor.visit self
    end

    def raise(exc : RuntimeError)
      ::raise TemplateError.new(token, exc, template)
    end

    module ParentStatement
      abstract def <<(new_child : Statement)

      abstract def accepts_children? : Bool
    end
  end
end

require "./statement/*"
