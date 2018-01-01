require "spec"
require "../../src/runtime/value"
require "../../src/runtime/bindings"

describe Crinja::Bindings do
  it "casts simple hash" do
    Crinja::Bindings.cast_variables({"foo" => "bar"}).should eq Variables{ "foo" => "bar" }
  end

  it "casts complex hash" do
    Crinja::Bindings.cast_variables({"foo" => ["hello", "world", 1], "banana" => {"split" => "mjam"}}).should eq Crinja::Variables{
      "foo"    => ["hello", "world", 1] of Crinja::Type,
      "banana" =>  Crinja::Dictionary { "split" => "mjam" }
    }
  end
end
