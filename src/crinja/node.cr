module Crinja
  abstract class Node
    getter token
    property end_token : Token?

    property parent : Node?
    property children : ::Array(Node) = [] of Node

    alias Token = Crinja::Lexer::Token

    def initialize(@token : Token)
    end

    abstract def render(env : Crinja::Environment) : Output

    def root
      parent.not_nil!.root
    end

    def template
      root.template
    end

    def name
      {{ @type.stringify.split("::").last.downcase }}
    end

    def block?
      false
    end

    def trim_left?
      token.trim_left
    end

    def trim_right?
      end_token.try(&.trim_right) || false
    end

    def trim_right_after_end?
      false
    end

    def <<(child : Node)
      children << child
      child.parent = self
    end

    def accept(visitor : Visitor)
      visitor.visit self
    end

    def render_children(io : IO, env : Crinja::Environment)
      children.each do |node|
        node.render(io, env)
      end
    end

    def to_s(io : IO)
      io << name
    end

    def inspect(io : IO, indent = 0)
      io << "<"
      to_s(io)
      inspect_arguments(io, indent)
      io << ">"

      inspect_children(io, indent + 1)

      io << "\n" << "  " * indent
      io << "</" << name
      inspect_end_arguments(io, indent)
      io << ">"
    end

    def inspect_arguments(io : IO, indent = 0)
      io << " start="
      token.inspect(io)
      unless end_token.nil?
        io << " end="
        end_token.not_nil!.inspect(io)
      end
    end

    def inspect_end_arguments(io : IO, indent = 0)
    end

    def inspect_children(io : IO, indent = 0)
      children.each do |node|
        io << "\n" << "  " * indent
        node.inspect(io, indent + 1)
      end
    end
  end
end

require "./node/*"
