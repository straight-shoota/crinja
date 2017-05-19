class Crinja::Statement
  class Root < Statement
    include ParentStatement

    getter children : Array(Statement) = [] of Statement
    property parent_node : Node?

    def evaluate(env : Environment) : Type
      if children.empty?
        nil
      else
        children.first.evaluate(env)
      end
    end

    def <<(statement : Statement)
      raise "Statement::Root already has a child: #{@children.inspect}" unless accepts_children?

      @children << statement
      statement.parent = self
    end

    def accepts_children?
      children.empty?
    end

    def root
      self
    end

    def root_node
      parent_node.try(&.root)
    end
  end

  class MultiRoot < Root
    include ArgumentsList

    def accepts_children?
      true
    end

    def evaluate(env : Crinja::Environment) : Type
      raise "cannot evaluate instance of #{self.class}"
    end
  end
end
