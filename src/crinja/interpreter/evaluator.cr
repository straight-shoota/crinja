class Crinja::Evaluator
  def initialize(@env : Environment)
  end

  def value(expression)
    Value.new self.evaluate(expression)
  end

  def evaluate(expression)
    raise expression.inspect
  end

  macro visit(*node_types)
    def evaluate(expression : {{
                                (node_types.map do |type|
                                  "Parser::#{type.id}"
                                end).join(" | ").id
                              }})
      ({{ yield }}).as(Type)
    end
  end

  visit Empty do
    raise "empty expression"
  end

  visit BinaryExpression, ComparisonExpression do
    op = @env.operators[expression.operator].as(Operator::Binary)
    left = evaluate expression.left
    right = evaluate expression.right
    op.value(@env, Value.new(left), Value.new(right))
  end

  visit UnaryExpression do
    op = @env.operators[expression.operator].as(Operator::Unary)
    right = evaluate expression.right
    op.value(@env, Value.new(right))
  end

  visit CallExpression do
    identifier = expression.identifier

    if identifier.is_a?(Parser::IdentifierLiteral)
      # identifier lookup for function calls is handled by `execute_call`
      callable = identifier.name
    else
      callable = value(identifier)
    end

    argumentlist = evaluate(expression.argumentlist).as(Array(Type)) # TODO: Remove self when https://github.com/crystal-lang/crystal/issues/236 is resolved
    keyword_arguments = expression.keyword_arguments.each_with_object(Hash(String, Type).new) do |(keyword, value), args|
      args[keyword.name] = evaluate value
    end

    @env.execute_call(callable, argumentlist, keyword_arguments)
  end

  visit FilterExpression do
    evaluate_filter @env.filters[expression.identifier.name], expression
  end

  visit TestExpression do
    !!evaluate_filter @env.tests[expression.identifier.name], expression
  end

  def evaluate_filter(callable, expression)
    argumentlist = evaluate(expression.argumentlist).as(Array(Type)).map { |a| Value.new a }
    keyword_arguments = expression.keyword_arguments.each_with_object(Hash(String, Value).new) do |(keyword, value), args|
      args[keyword.name] = value(value)
    end

    target = value expression.target
    callable.call Arguments.new(@env, argumentlist, keyword_arguments, target: target)
  end

  visit MemberExpression do
    identifier = evaluate expression.identifier
    member = expression.member.name
    Resolver.resolve_attribute(member, identifier)
  end

  visit IndexExpression do
    identifier = evaluate expression.identifier
    argument = evaluate expression.argument
    Resolver.resolve_item(argument, identifier)
  end

  visit ExpressionList do
    values = [] of Type
    expression.children.each do |child|
      if child.is_a?(Parser::SplashOperator)
        splash = evaluate(child.right)
        if splash.is_a?(Array(Type))
          values += splash
        else
          raise TypeError.new(Value.new(splash), "#{child.right} needs to be an array for splash operator").at(expression)
        end
      else
        values << evaluate child
      end
    end
    values
  end

  visit IdentifierList do
    raise "identifier list not implemented"
  end

  visit NullLiteral do
    nil
  end

  visit IdentifierLiteral do
    @env.resolve(expression.name)
  end

  visit SplashOperator do
    evaluate(expression.right)
  end

  visit StringLiteral, FloatLiteral, IntegerLiteral, BooleanLiteral do
    expression.value
  end

  visit ArrayLiteral do
    expression.children.map do |child|
      self.evaluate(child).as(Type)
    end
  end

  visit TupleLiteral do
    expression.children.map do |child|
      self.evaluate(child).as(Type)
    end
  end

  visit DictLiteral do
    expression.children.each_with_object(Hash(Type, Type).new) do |(keyword, value), args|
      args[evaluate keyword] = self.evaluate(value)
    end
  end
end
