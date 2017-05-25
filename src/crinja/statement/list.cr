class Crinja::Statement
  class List < Statement
    include ParentStatement

    property children : Array(Statement) = [] of Statement

    def <<(statement : Statement)
      children << statement
      statement.parent = self
    end

    def accepts_children?
      true
    end
  end
end
