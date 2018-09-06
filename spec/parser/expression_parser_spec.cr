require "../spec_helper.cr"

describe Crinja::Parser::ExpressionParser do
  it "" do
    expression = parse_expression(%( "foo"))
    expression.should be_a(Crinja::AST::StringLiteral)
  end

  it "" do
    expression = parse_expression(%(1 + 2))
    expression.should be_a(Crinja::AST::BinaryExpression)
    Crinja.new.evaluate(expression).should eq 3
  end

  it "parses member operator" do
    expression = parse_expression(%(foo.bar))
    expression.should be_a(Crinja::AST::MemberExpression)
  end

  it "parses single parenthesis tuple" do
    expression = parse_expression(%(("foo", 1)))
    expression.should be_a(Crinja::AST::TupleLiteral)
  end

  it "parses integer as identifier member" do
    expression = parse_expression(%(foo.1))
    expression.should be_a(Crinja::AST::MemberExpression)
  end

  it "parse double parenthesis" do
    expression = parse_expression("dict(foo=(1, 2))")
    expression.should be_a(Crinja::AST::CallExpression)
  end

  it "parses expression as named argument value" do
    expression = parse_expression("self(n=n-1)")
    expression.should be_a(Crinja::AST::CallExpression)
  end

  it "parses integer as member access" do
    expression = parse_expression("foo.1.bar")
    expression.should be_a(Crinja::AST::MemberExpression)
  end
end
