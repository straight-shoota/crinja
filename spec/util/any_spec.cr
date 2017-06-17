require "spec"

require "../../src/crinja/runtime/value"

describe Crinja::Value do
  describe "#each" do
    it "creates empty iterator for Undefined" do
      Crinja::Value.new(Crinja::Undefined.new).each.to_a.should eq([] of Crinja::Value)
    end

    it "creates iterator" do
      Crinja::Value.new([1, 2, "3"].map(&.as(Crinja::Type))).each.to_a.should eq([Crinja::Value.new(1), Crinja::Value.new(2), Crinja::Value.new("3")])
    end
  end
end
