require "../spec_helper"

describe "expressions with identifiers" do
  it "resolves a simple variable lookup" do
    expression = Crinja::AST::IdentifierLiteral.new("foo")

    env = Crinja.new
    env.context.merge!({"foo" => "bar"})

    env.evaluate(expression).should eq Crinja::Value.new("bar")
  end

  it "resolves lookup sequence" do
    evaluate_expression(%(posts[0].user.name), {"posts" => [{"user" => {"name" => "Barry"}}]}).should eq("Barry")
  end

  it "resolves IndexExpression" do
    evaluate_expression_raw(%(posts[0]), {"posts" => [true]}).should be_true
  end

  it "raises with lookup name if undefined (IndexExpression)" do
    expect_raises(Crinja::UndefinedError, "posts is undefined") do
      evaluate_expression(%(posts[0].user.name))
    end
  end

  it "raises with lookup name if undefined (MemberExpression)" do
    expect_raises(Crinja::UndefinedError, "posts[0] is undefined") do
      evaluate_expression_raw(%(posts[0].user.name), {"posts" => [] of Crinja::Value})
    end
  end

  it "raises with lookup name if undefined (MemberExpression, MemberExpression)" do
    expect_raises(Crinja::UndefinedError, "posts[0].user is undefined") do
      evaluate_expression_raw(%(posts[0].user.name), {"posts" => [true]})
    end
  end

  it "returns lookup name in Undefined" do
    undefined = evaluate_expression_raw(%(posts[0].user.name), {"posts" => [{"user" => nil}]}).as(Crinja::Undefined)
    undefined.name.should eq "posts[0].user.name"
  end
end
