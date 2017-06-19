require "../spec_helper.cr"

private def parse(string)
  env = Crinja::Environment.new
  begin
    lexer = Crinja::Parser::ExpressionLexer.new(env.config, string)
    parser = Crinja::Parser::ExpressionParser.new(lexer)
    parser.parse
  rescue e : TemplateError
    e.template = Crinja::Template.new(string, env, run_parser: false)
    raise ExceptionWrapper.new(cause: e)
  end
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

  it "parses expression as named argument value" do
    expression = parse("self(n=n-1)")
    expression.should be_a(Crinja::AST::CallExpression)
  end

  it "parses integer as member access" do
    expression = parse("foo.1.bar")
    expression.should be_a(Crinja::AST::MemberExpression)
  end
end
