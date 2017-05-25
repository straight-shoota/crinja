module Crinja
  abstract class Visitor
    abstract def visit(node : Node)

    def visit(template : Template)
      template.root.accept(self)
    end
  end

  abstract class Node
    def accept(visitor : Visitor)
      visitor.visit self
    end
  end
end
