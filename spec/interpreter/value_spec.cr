require "../spec_helper"

describe Crinja::Value do
  it "compare pytuple" do
    PyTuple.new("foo", 1).should eq PyTuple.new("foo", 1)
  end
end
