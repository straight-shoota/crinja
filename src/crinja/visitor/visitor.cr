module Crinja
  abstract class Visitor
    abstract def visit(node : Node)
  end
end
