require "../spec_helper"

describe Crinja::Value do
  it "compare pytuple" do
    Crinja::Tuple.new("foo", 1).should eq Crinja::Tuple.new("foo", 1)
  end

  describe "raw_each" do
    it "array" do
      a = [1, 2, 3]
      Crinja::Value.new(a).map(&.raw).to_a.should eq a.map(&.as(Crinja::Raw))
    end

    it "hash" do
      hash = Crinja::Dictionary.new
      hash[Crinja::Value.new "foo"] = Crinja::Value.new 1
      hash[Crinja::Value.new "bar"] = Crinja::Value.new 3
      arr = [Crinja::Tuple.new("foo", 1), Crinja::Tuple.new("bar", 3)]
      Crinja::Value.new(hash).map(&.raw).to_a.should eq arr.map(&.as(Crinja::Raw))
    end
  end

  describe "each" do
    it "array" do
      a = [1, 2, 3]
      Crinja::Value.new(a).to_a.should eq a.map { |item| Crinja::Value.new(item) }
    end

    it "hash" do
      hash = Crinja::Dictionary.new
      hash[Crinja::Value.new "foo"] = Crinja::Value.new 1
      hash[Crinja::Value.new "bar"] = Crinja::Value.new 3
      arr = [Crinja::Tuple.new("foo", 1), Crinja::Tuple.new("bar", 3)]
      Crinja::Value.new(hash).to_a.should eq arr.map { |item| Crinja::Value.new(item) }
    end

    it "#each" do
      Crinja::Value.new([1]).each.should be_a(Iterator(Crinja::Value))
      Crinja::Value.new([1]).each.each_with_index do |item, index|
        item.should eq Crinja::Value.new 1
        index.should eq 0
      end

      Crinja::Value.new([1]).each_with_index do |item, index|
        item.should eq Crinja::Value.new 1
        index.should eq 0
      end
    end

    it "raw_#each" do
      # be_a matcher doesn't support uninstantiated generic type
      Crinja::Value.new([1]).raw_each.is_a?(Crinja::Value::RawIterator).should be_true

      Crinja::Value.new([1]).raw_each.each_with_index do |item, index|
        item.should eq 1
        index.should eq 0
      end

      count = 0
      Crinja::Value.new([1]).raw_each do |item|
        item.should eq 1
        count += 1
      end
      count.should eq 1
    end
  end
end
