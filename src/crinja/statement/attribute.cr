class Crinja::Statement
  class Attribute < Statement
    include ParentStatement

    property attribute : Statement?
    property base : Statement
    property member_operator : Bool = false

    def initialize(token, @base)
      super(token)
      @base.parent = self
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
