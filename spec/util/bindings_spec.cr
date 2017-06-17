require "spec"
require "../../src/crinja/runtime/value"
require "../../src/crinja/runtime/bindings"

describe Crinja::Bindings do
  it "casts simple hash" do
    typehash = Hash(String, Crinja::Type).new
    typehash["foo"] = "bar"
    Crinja::Bindings.cast_bindings({"foo" => "bar"}).should eq(typehash)
  end

  it "casts complex hash" do
    typehash = Hash(String, Crinja::Type).new
    typehash["foo"] = ["hello", "world", 1] of Crinja::Type
    banana = Hash(Crinja::Type, Crinja::Type).new
    banana["split"] = "mjam"
    typehash["banana"] = banana
    Crinja::Bindings.cast_bindings({"foo" => ["hello", "world", 1], "banana" => {"split" => "mjam"}}).should eq(typehash)
  end
end
