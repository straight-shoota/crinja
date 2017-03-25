require "./spec_helper"

describe Crinja::Statement::Dict do
  it "parses dict" do
    evaluate_statement(%({ "foo": "bar", target: "world" }), {"target" => "hello"}).should eq(%({"foo" => "bar", "hello" => "world"}))
  end
end
