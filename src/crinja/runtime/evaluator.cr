# The evaluator traverses through an abstract syntax tree to evaluate all expressions and return a
# final value.
class Crinja::Evaluator
  # Creates a new evaluator for the environment *env*.
  def initialize(@env : Environment)
  end

  # Evaluates an expression inside this evaluatores environment and returns a `Value` object.
  def value(expression)
    Value.new self.evaluate(expression)
  end

  # Evaluates an expression inside this evaluatores environment and returns a `Type` object.
  def evaluate(expression)
    raise expression.inspect
  end

  private macro visit(*node_types)
    # :nodoc:
    def evaluate(expression : {{
                                (node_types.map do |type|
                                  "AST::#{type.id}"
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

    # First check if there is a literal function or macro registered (like "function" or "group.function").
    callable_name = identifier_or_member(identifier)

    callable = @env.resolve_callable(callable_name) if callable_name

    if !callable.is_a?(Callable | Callable::Proc) && identifier.is_a?(AST::MemberExpression)
      callable = call_on_member(identifier)
    end

    unless callable.is_a?(Callable | Callable::Proc)
      begin
        callable = @env.resolve_callable!(value(identifier))
      rescue e : TypeError
        e.at(expression)
        raise e
      end
    end

    argumentlist = evaluate(expression.argumentlist).as(Array(Type))
    keyword_arguments = expression.keyword_arguments.each_with_object(Hash(String, Type).new) do |(keyword, value), args|
      args[keyword.name] = evaluate value
    end

    @env.execute_call(callable, argumentlist, keyword_arguments)
  end

  private def call_on_member(expression : AST::MemberExpression)
    identifier = evaluate expression.identifier
    member = expression.member.name
    Resolver.resolve_method(member, identifier)
  end

  private def identifier_or_member(identifier : AST::IdentifierLiteral)
    identifier.name
  end

  private def identifier_or_member(expr : AST::MemberExpression)
    identifier = identifier_or_member(expr.identifier)
    member = identifier_or_member(expr.member)

    "#{identifier}.#{member}" if identifier && member
  end

  private def identifier_or_member(expr)
    nil
  end

  visit FilterExpression do
    evaluate_filter @env.filters[expression.identifier.name], expression
  end

  visit TestExpression do
    !!evaluate_filter @env.tests[expression.identifier.name], expression
  end

  private def evaluate_filter(callable, expression)
    argumentlist = evaluate(expression.argumentlist).as(Array(Type)).map { |a| Value.new a }
    keyword_arguments = expression.keyword_arguments.each_with_object(Hash(String, Value).new) do |(keyword, value), args|
      args[keyword.name] = value(value)
    end

    target = value expression.target
    callable.call Callable::Arguments.new(@env, argumentlist, keyword_arguments, target: target)
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
      if child.is_a?(AST::SplashOperator)
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

  visit ValuePlaceholder do
    expression.value
  end
end
