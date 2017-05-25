class Crinja::Statement
  class Subexpression < Statement
    include ParentStatement

    getter child : Statement?

    def <<(statement : Statement)
      raise "Statement::Subexpression already has a child: #{@child.inspect}" unless accepts_children?

      @child = statement
      statement.parent = self
    end

    def accepts_children?
      @child.nil?
    end
  end
end
