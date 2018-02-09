require "../spec_helper"

describe Crinja do
  pending "variables constructor" do
    Crinja::Variables{"foo" => "bar"}.should eq Crinja::Variables{"foo" => Crinja::Value.new("bar")}
  end

  it "casts simple hash" do
    Crinja.variables({"foo" => "bar"}).should eq Crinja::Variables{"foo" => Crinja::Value.new("bar")}
  end

  it "casts complex hash" do
    Crinja.variables({"foo" => ["hello", "world", 1], "banana" => {"split" => "mjam"}}).should eq Crinja::Variables{
      "foo"    => Crinja::Value.new(["hello", "world", 1]),
      "banana" => Crinja::Value.new Crinja::Dictionary{Crinja::Value.new("split") => Crinja::Value.new("mjam")},
    }
  end

  it "casts iterator" do
    iterator = (0..4).each
    Crinja.variables({"items" => iterator}).["items"].raw.should eq Crinja::Value::Iterator.new(iterator)
  end

  it "casts array" do
    Crinja::Value.new([1]).should eq Crinja::Value.new([Crinja::Value.new(1)])
  end
end
