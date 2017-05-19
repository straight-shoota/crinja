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

    def evaluate(env : Environment) : Type
      object = base.value(env)
      raise TemplateSyntaxError.new(token, "empty attribute") if attribute.nil?

      if member_operator
        raise TemplateSyntaxError.new(token, "member operator expects a name as attribute") unless attribute.is_a?(Statement::Name)
        member = attribute.as(Statement::Name).name
        env.resolve_attribute(member, object)
      else
        item = attribute.not_nil!.value(env)
        value = env.resolve_item(item.to_s, object)
        value
      end
    end

    def accepts_children?
      !attribute.nil?
    end
  end
end
