require "./visitor"

module Crinja
  # This visitor prints the node tree into an xml-like string for debugging purposes.
  class Visitor::Inspector < Visitor(Parser::ASTNode)
    def initialize(@io : IO, @indent = 0)
    end

    def visit(expression)
    end

    private def open(name)
      open(name) { }
    end
    private def open(name)
      @io << "<" << name
      yield
      @io << ">"
      @indent += 1
    end

    private def close(name)
      close(name) { }
    end
    private def close(name)
      @indent -= 1
      nl
      @io << "</" << name
      yield
      @io << ">"
    end

    private def nl
      @io << "\n" << "  " * @indent
      @io
    end

    def visit(node : Node)
      open(node.name) { inspect_start_attributes(node) }

      inspect_content(node)

      close(node.name) { inspect_end_attributes(node) }
    end

    def inspect_content(node : Node)
      inspect_children(node)
    end

    def inspect_start_attributes(node : Node)
      inspect_token_arguments(node)
    end

    def inspect_token_arguments(node : Node)
      @io << " start="
      node.token.inspect(@io)
      unless (end_token = node.end_token).nil?
        @io << " end="
        end_token.inspect(@io)
      end
    end

    def inspect_end_attributes(node : Node)
    end

    def inspect_children(node : Node)
      node.children.each do |node|
        nl
        node.accept(self)
      end
    end

    def inspect_children(node : Node::Expression)
      node.statement.accept(self)
    end

    def inspect_start_attributes(node : Node::Tag)
      inspect_token_arguments(node)

      @io << " tag=" << node.tag.name
      @io << " trim?="
      @io << if node.trim_right?
        node.trim_left? ? "both" : "right"
      else
        node.trim_left? ? "left" : "none"
      end
    end

    def inspect_content(node : Node::Tag)
      inspect_arguments(node)
      inspect_children(node)
    end

    def inspect_arguments(node)
      unless node.varargs.empty?
        nl
        open "varargs"
        node.varargs.each do |arg|
          nl
          arg.accept(self)
        end
        close "varargs"
      end
      unless node.kwargs.empty?
        nl
        node.kwargs.each do |kw, arg|
          open("kwarg") { @io << " name=\"" << kw << "\"" }
          nl
          arg.accept(self)
          close "kwarg"
        end
      end
    end

    def inspect_end_attributes(node : Node::Tag)
      unless (end_tag = node.end_tag).nil?
        inspect_token_arguments(end_tag)
      end
    end

    def inspect_start_attributes(node : Node::Text)
      @io << " trim="
      @io << if node.trim_right
        if node.trim_left
          "both"
        else
          "right"
        end
      elsif node.trim_left
        "left"
      else
        "none"
      end

      @io << " left_is_block" if node.left_is_block
      @io << " right_is_block" if node.right_is_block
    end

    def inspect_content(node : Node::Text)
      node.token.value.to_s(@io)
    end

    # ## Statement

    def visit(node : Statement)
      open(node.statement_name) { inspect_start_attributes(node) }

      inspect_content(node)

      close(node.statement_name)
    end

    def inspect_start_attributes(node : Statement)
      inspect_token(node.token)
    end

    def inspect_token(token)
      @io << " token="
      token.inspect(@io)
    end

    def inspect_content(node : Statement)
      inspect_children(node)
    end

    def inspect_children(node : Statement)
    end

    def inspect_content(node : Statement::Dict::Entry)
      nl << "- "
      node.key.accept(self)
      nl << "- "
      node.value.try(&.accept(self))
    end

    def inspect_content(node : Statment::ArgumentsList)
      inspect_arguments(node)
      inspect_children(node)
    end

    def inspect_start_attributes(node : Statement::Attribute)
      inspect_token(node.token)
      @io << " member_operator" if node.member_operator
    end

    def inspect_content(node : Statement::Attribute)
      @io << "\n" << "  " * (@indent + 1)
      node.base.accept(self)
      @io << "\n" << "  " * (@indent + 1)
      node.attribute.try &.accept(self)
    end

    def inspect_content(node : Statement::Call)
      open "callable"
      node.target.accept(self)
      close "callable"

      inspect_children(node)
    end

    def inspect_start_attributes(node : Statement::Filter)
      inspect_token(node.token)
      @io << " name=" << node.name
    end

    def inspect_content(node : Statement::Filter)
      open "target"
      node.target.accept(self)
      close "target"

      inspect_children(node)
    end

    def inspect_start_attributes(node : Statement::Function)
      inspect_token(node.token)
      @io << " name=" << node.name
    end

    def inspect_children(node : Statement::List)
      node.children.each do |child|
        @io << "\n" << "  " * (@indent + 1)
        child.accept(self)
      end
    end

    def inspect_content(node : Statement::Literal)
      nl
      node.token.value.to_s(@io)
    end

    def inspect_start_attributes(node : Statement::Name)
      inspect_token(node.token)
      @io << " name="
      @io << node.token.value
    end

    def inspect_start_attributes(node : Statement::Operator)
      @io << " operator=" << node.operator
    end

    def inspect_children(node : Statement::Operator)
      node.operands.each do |op|
        nl
        op.accept(self)
      end
    end

    def visit(node : Statement::Root)
      node.children.each do |child|
        nl
        child.accept(self)
      end
    end

    def inspect_children(node : Statement::SplashOperator)
      node.operand.try &.accept(self)
    end

    def inspect_children(node : Statement::Subexpression)
      unless (child = node.child).nil?
        nl
        child.accept(self)
      end
    end

    def inspect_children(node : Statement::Tuple)
      node.children.each do |child|
        nl
        child.accept(self)
      end
    end
  end
end
