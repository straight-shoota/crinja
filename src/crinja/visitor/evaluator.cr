require "./visitor"

abstract class Crinja::Visitor
  class Evaluator < Visitor
    def initialize(@env : Environment)
    end

    def value(statement)
      Value.new statement.accept(self)
    end

    def visit(node : Node)
      raise node.class.to_s
    end

    def visit(statement : Statement)
      raise statement.class.to_s
    end

    def visit(statement : Statement::AttributeOperator)
      object = statement.object.accept(self)
      raise TemplateSyntaxError.new(statement.token, "empty attribute") if statement.attribute.nil?

      item = statement.attribute.not_nil!.accept(self)
      value = @env.resolve_item(item.to_s, object)
      value
    end

    def visit(statement : Statement::Call)
      if (name_stmt = statement.target).is_a?(Statement::Name)
        calling = Variable.new name_stmt.token.value
      else
        calling = value(name_stmt)
      end

      @env.execute_call(calling) do |arguments|
        statement.varargs.each do |stmt|
          if stmt.is_a?(Statement::SplashOperator)
            stmt.operand.not_nil!.accept(self).as(Array(Type)).each do |arg|
              arguments.varargs << Value.new(arg)
            end
          else
            arguments.varargs << value(stmt)
          end
        end

        statement.kwargs.each do |k, stmt|
          arguments.kwargs[k] = value(stmt)
        end
      end
    end

    def visit(statement : Statement::Dict)
      hash = Hash(Type, Type).new
      statement.children.each do |entry|
        key, value = entry.accept(self)
        hash[key] = value
      end

      hash
    end

    def visit(statement : Statement::Dict::Entry)
      {statement.key.accept(self), statement.value.not_nil!.accept(self)}.as(::Tuple(Type, Type))
    end

    def resolve_filter(statement : Statement::Filter)
      @env.filters[statement.name]
    end

    def resolve_target(statement)
      statement.target.accept(self)
    end

    def visit(statement : Statement::Filter)
      evaluate_filter(statement)
    end

    private def evaluate_filter(statement)
      filter = resolve_filter(statement)

      arguments = Arguments.new(@env)
      arguments.target = Value.new resolve_target(statement)

      statement.varargs.each do |stmt|
        arguments.varargs << value(stmt)
      end

      statement.kwargs.each do |k, stmt|
        arguments.kwargs[k] = value(stmt)
      end

      filter.call(arguments)
    end

    def visit(statement : Statement::Function)
      function = @env.functions[statement.name]

      arguments = Arguments.new(@env)

      statement.varargs.each do |stmt|
        arguments.varargs << value(stmt)
      end

      statement.kwargs.each do |k, stmt|
        arguments.kwargs[k] = value(stmt)
      end

      function.call(arguments)
    end

    def visit(statement : Statement::List)
      array = [] of Type
      statement.children.each do |child|
        array << child.accept(self)
      end
      array
    end

    def visit(statement : Statement::Literal)
      token = statement.token
      case token.kind
      when Kind::INTEGER
        token.value.to_i64
      when Kind::FLOAT
        token.value.to_f
      when Kind::STRING
        token.value.to_s
      when Kind::BOOL
        token.value.downcase == "true"
      when Kind::NONE
        nil
      else
        raise "Unrecognized literal token value #{token.kind}"
      end
    end

    def visit(statement : Statement::Name)
      @env.resolve(statement.name)
    end

    def visit(statement : Statement::MemberOperator)
      object = statement.object.accept(self)

      @env.resolve_attribute(statement.attribute.value, object)
    end

    def visit(statement : Statement::Operator)
      operands = statement.operands.map do |op|
        op.accept(self).as(Type)
      end
      statement.operator.value(@env, operands)
    end

    def visit(statement : Statement::Root)
      if statement.children.empty?
        nil
      else
        statement.children.first.accept(self)
      end
    end

    def visit(statement : Statement::Subexpression)
      statement.child.not_nil!.accept(self)
    end

    def visit(statement : Statement::Test)
      !! evaluate_filter(statement)
    end

    private def resolve_filter(statement : Statement::Test)
      @env.tests[statement.name]
    end

    # TODO: Create a wrapper `PyTuple`
    def visit(statement : Statement::Tuple)
      array = [] of Type
      statement.children.each do |child|
        array << child.accept(self)
      end
      array
    end

  end
end
