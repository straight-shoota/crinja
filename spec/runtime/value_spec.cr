require "spec"

require "../../src/runtime/value"

describe Crinja::Value do
  describe "#each" do
    it "creates empty iterator for Undefined" do
      Crinja::Value.new(Crinja::Undefined.new).to_a.should eq([] of Crinja::Value)
    end

    it "creates iterator" do
      Crinja::Value.new([1, 2, "3"]).to_a.should eq([Crinja::Value.new(1), Crinja::Value.new(2), Crinja::Value.new("3")])
    end
  end
end
