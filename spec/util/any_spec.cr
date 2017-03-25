require "spec"

require "../../src/crinja/any"

describe Crinja::Any do
  describe "#each" do
    it "creates empty iterator for Undefined" do
      Crinja::Any.new(Crinja::Undefined.new).each.to_a.should eq([] of Crinja::Any)
    end

    it "creates iterator" do
      Crinja::Any.new([1, 2, "3"].map(&.as(Crinja::Type))).each.to_a.should eq([Crinja::Any.new(1), Crinja::Any.new(2), Crinja::Any.new("3")])
    end
  end
end
