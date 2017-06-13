require "../spec_helper"

describe "expressions" do
  it "`none` evaluates to 'none'" do
    evaluate_expression(%(none)).should eq "none"
    evaluate_expression(%(x), {x: nil}).should eq "none"
    render(%({{ none }}|{{ x }}), {x: nil}).should eq "none|none"
  end

  it "parses double array" do
    evaluate_expression(%([[1,2,3]])).should eq "[[1, 2, 3]]"
  end
end
