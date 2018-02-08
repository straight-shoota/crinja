require "../spec_helper"

describe Crinja::Bindings do
  it "casts simple hash" do
    Crinja::Bindings.cast_variables({"foo" => "bar"}).should eq Crinja::Variables{ "foo" => Crinja::Value.new("bar") }
  end

  it "casts complex hash" do
    Crinja::Bindings.cast_variables({"foo" => ["hello", "world", 1], "banana" => {"split" => "mjam"}}).should eq Crinja::Variables{
      "foo"    => Crinja::Value.new(["hello", "world", 1]),
      "banana" => Crinja::Value.new Crinja::Dictionary{ Crinja::Value.new("split") => Crinja::Value.new("mjam") }
    }
  end

  it "casts iterator" do
    iterator = (0..4).each
    Crinja::Bindings.cast_variables({"items" => iterator}).["items"].raw.should eq Crinja::Value::Iterator.new(iterator)
  end
end
