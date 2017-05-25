module Crinja
  abstract class Node
    getter token
    property end_token : Token?

    property parent : Node?
    property children : ::Array(Node) = [] of Node

    alias Token = Crinja::Lexer::Token

    def initialize(@token : Token)
    end

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

    def to_s(io : IO)
      io << name
    end

    def inspect(io)
      accept Crinja::Visitor::Inspector.new(io)
    end
  end
end

require "./node/*"
