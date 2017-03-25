class Crinja::Statement
  class List < Statement
    include ParentStatement

    property children : Array(Statement) = [] of Statement

    def <<(statement : Statement)
      children << statement
      statement.parent = self
    end

    def evaluate(env : Crinja::Environment) : Type
      array = [] of Type
      children.each do |child|
        array << child.value(env).raw
      end
      array
    end

    def inspect_children(io : IO, indent = 0)
      children.each do |child|
        io << "\n" << "  " * (indent + 1)
        child.to_s(io)
      end
    end

    def accepts_children?
      true
    end
  end
end
