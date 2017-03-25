require "./spec_helper"

describe Crinja::Function do
  describe "dict" do
    it "creates dict" do
      evaluate_statement(%(dict(foo="bar"))).should eq(%({"foo" => "bar"}))
    end
  end
end
