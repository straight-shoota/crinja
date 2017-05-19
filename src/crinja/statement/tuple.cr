class Crinja::Statement
  class Tuple < Statement
    include ParentStatement

    property children : Array(Statement) = [] of Statement

    def <<(statement : Statement)
      children << statement
      statement.parent = self
    end

    # TODO: Create a wrapper `PyTuple`
    def evaluate(env : Environment) : Type
      array = [] of Type
      children.each do |child|
        array << child.value(env).raw
      end
      array
    end

    def accepts_children?
      true
    end
  end
end
