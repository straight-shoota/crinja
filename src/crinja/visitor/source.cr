require "./visitor"

# The source visitor transforms a template tree into Jinja source code.
module Crinja
  class Visitor::Source < Visitor
    def initialize(@io : IO)
    end

    def visit(node : Node)
      node.children.each &.accept(self)
    end

    def visit(node : Node::Text)
      print_token node.token
    end

    def visit(node : Node::Note)
      print_token node.token
    end

    def visit(node : Node::Expression)
      print_token node.token

      node.statement.accept(self)

      print_token node.end_token
    end

    def visit(node : Node::Tag)
      print_token node.token
      print_token node.name_token

      node.varargs.each &.accept(self)

      # node.kwargs.each &.accept(self)

      print_token node.end_token

      node.children.each &.accept(self)

      node.end_tag.try &.accept(self)
    end

    def visit(node : Statement::Operator)
      if node.unary?
        print_token node.token
      end
      node.operands[0].accept(self)
      unless node.unary?
        print_token node.token
        node.operands[1].accept(self)
      end
    end

    def visit(node : Statement::MemberOperator)
      node.object.accept(self)
      print_token node.token
      print_token node.attribute
    end

    def visit(node : Statement::Attribute)
      node.base.accept(self)
      print_token node.token
      node.attribute.try &.accept(self)
    end

    def visit(node : Statement::ParentStatement)
      if node.responds_to? :children
        node.children.each &.accept(self)
      else
        @io << "(--" << node.class.to_s << "--)"
      end
    end

    def visit(node : Statement::Name)
      print_token node.token
    end

    def visit(node : Statement::Filter)
      node.target.accept(self)

      print_token node.token
      print_token node.name_token

      node.varargs.each &.accept(self)
    end

    def visit(node : Statement)
      @io << "(@@" << node.class.to_s << "@@)"
    end

    protected def print_token(token : Lexer::Token?)
      unless token.nil?
        @io << token.whitespace_before << token.value << token.whitespace_after
      end
    end
  end
end
