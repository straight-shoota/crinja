require "../spec_helper"

describe Crinja::Value do
  it "compare pytuple" do
    PyTuple.new("foo", 1).should eq PyTuple.new("foo", 1)
  end

  describe "raw_each" do
    it "array" do
      a = [1, 2, 3]
      Crinja::Value.new(a.map(&.as(Crinja::Type))).raw_each.to_a.should eq a
    end

    it "hash" do
      hash = Crinja::Dictionary.new
      hash["foo"] = 1
      hash["bar"] = 3
      arr = [] of Type
      arr << PyTuple.new("foo", 1)
      arr << PyTuple.new("bar", 3)
      Crinja::Value.new(hash).raw_each.to_a.should eq arr
    end
  end

  describe "each" do
    it "array" do
      a = [1, 2, 3]
      Crinja::Value.new(a.map(&.as(Crinja::Type))).each.to_a.should eq a.map { |item| Crinja::Value.new(item) }
    end

    it "hash" do
      hash = Crinja::Dictionary.new
      hash["foo"] = 1
      hash["bar"] = 3
      arr = [] of Crinja::Type
      arr << Crinja::PyTuple.new("foo", 1)
      arr << Crinja::PyTuple.new("bar", 3)
      Crinja::Value.new(hash).each.to_a.should eq arr.map { |item| Crinja::Value.new(item) }
    end
  end
end
