require "../spec_helper"

describe "expressions with identifiers" do
  it "resolves a simple variable lookup" do
    expression = Crinja::Parser::IdentifierLiteral.new("foo")

    env = Crinja::Environment.new
    env.context.merge!({"foo" => "bar"})

    env.evaluate(expression).should eq("bar")
  end

  it "resolves lookup sequence" do
    evaluate_expression(%(posts[0].user.name), {"posts" => [{"user" => {"name" => "Barry"}}]}).should eq("Barry")
  end
end
