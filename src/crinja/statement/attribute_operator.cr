class Crinja::Statement
  class AttributeOperator < Statement
    include ParentStatement

    property object : Statement
    property attribute : Statement?

    def initialize(token, @object)
      super(token)
      @object.parent = self
    end

    def <<(statement : Statement)
      raise TemplateSyntaxError.new(statement.token, "adding second attribute to #{self}") unless attribute.nil?

      @attribute = statement
      statement.parent = self
    end

    def accepts_children?
      !attribute.nil?
    end
  end
end
