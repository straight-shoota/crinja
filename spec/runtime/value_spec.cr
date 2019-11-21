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

  it "#as_time" do
    time = Time.utc
    Crinja::Value.new(time).as_time.should eq time

    expect_raises Crinja::Error, "Unexpected type in Crinja value" do
      Crinja::Value.new(nil).as_time
    end

    expect_raises Crinja::Error, "Unexpected type in Crinja value" do
      Crinja::Value.new("time").as_time
    end
  end

  it "#as_undefined" do
    Crinja::Value.new(Crinja::UNDEFINED).as_undefined.should eq Crinja::UNDEFINED

    expect_raises Crinja::Error, "Unexpected type in Crinja value" do
      Crinja::Value.new(nil).as_undefined
    end

    expect_raises Crinja::Error, "Unexpected type in Crinja value" do
      Crinja::Value.new("time").as_undefined
    end
  end
end
