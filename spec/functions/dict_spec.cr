require "../spec_helper.cr"

describe "function dict" do
  it "creates dict" do
    evaluate_expression(%(dict(foo="bar"))).should eq(%({"foo" => "bar"}))
  end
end
