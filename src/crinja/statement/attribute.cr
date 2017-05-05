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

    def evaluate(env : Crinja::Environment) : Type
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

    def inspect_arguments(io : IO, indent = 0)
      io << " member_operator" if member_operator
    end

    def inspect_children(io : IO, indent = 0)
      io << "\n" << "  " * (indent + 1)
      base.inspect(io, indent + 1)
      io << "\n" << "  " * (indent + 1)
      attribute.not_nil!.inspect(io, indent + 1) unless attribute.nil?
    end

    def accepts_children?
      !attribute.nil?
    end
  end
end
