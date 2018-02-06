require "../spec_helper"

describe "expressions with identifiers" do
  it "resolves a simple variable lookup" do
    expression = Crinja::AST::IdentifierLiteral.new("foo")

    env = Crinja::Environment.new
    env.context.merge!({"foo" => "bar"})

    env.evaluate(expression).should eq("bar")
  end

  it "resolves lookup sequence" do
    evaluate_expression(%(posts[0].user.name), {"posts" => [{"user" => {"name" => "Barry"}}]}).should eq("Barry")
  end

  it "shows lookup name if undefined" do
    expect_raises(Crinja::UndefinedError, "posts is undefined") do
      evaluate_expression(%(posts[0].user.name))
    end
  end

  it "shows lookup name if undefined" do
    undefined = evaluate_expression_raw(%(posts[0].user.name), {"posts" => [{"user" => nil}]}).as(Crinja::Undefined)
    undefined.name.should eq "posts[0].user.name"
  end
end
