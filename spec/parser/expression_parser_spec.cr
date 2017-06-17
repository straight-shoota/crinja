require "../spec_helper.cr"

private def parse(string)
  env = Crinja::Environment.new
  lexer = Crinja::Parser::ExpressionLexer.new(env.config, string)
  parser = Crinja::Parser::ExpressionParser.new(lexer)
  parser.parse
end

describe Crinja::Parser::ExpressionParser do
  it "" do
    expression = parse %( "foo")
    expression.should be_a(Crinja::AST::StringLiteral)
  end

  it "" do
    expression = parse %(1 + 2)
    expression.should be_a(Crinja::AST::BinaryExpression)
    Crinja::Environment.new.evaluate(expression).should eq 3
  end

  it "parses member operator" do
    expression = parse %(foo.bar)
    expression.should be_a(Crinja::AST::MemberExpression)
  end

  it "parses single parenthesis tuple" do
    expression = parse(%(("foo", 1)))
    expression.should be_a(Crinja::AST::TupleLiteral)
  end

  it "parses integer as identifier member" do
    expression = parse(%(foo.1))
    expression.should be_a(Crinja::AST::MemberExpression)
  end

  it "parse double parenthesis" do
    expression = parse("dict(foo=(1, 2))")
  end
end
