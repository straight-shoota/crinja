require "../spec_helper"

describe Crinja::AST::DictLiteral do
  it "parses dict" do
    evaluate_expression(%({ "foo": "bar", target: "world" }), {"target" => "hello"}).should eq(%({"foo" => "bar", "hello" => "world"}))
  end

  it "parses dict at end of expression" do
    render(%({{ { "foo": "bar" }}})).should eq %({"foo" => "bar"})
  end

  it "parses \"}}}\" at end of expression" do
    render(%({{ "foo" }}})).should eq %(foo})
  end
end
