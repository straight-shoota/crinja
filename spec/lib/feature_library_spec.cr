require "../spec_helper"

describe Crinja::FeatureLibrary do
  it "adds feature" do
    flib = Crinja::Filter::Library.new register_defaults: false

    flib.size.should eq 0

    flib.name.should be "filter"

    filter = Crinja.filter() { }
    flib["myfilter"] = filter

    flib.has_key?("myfilter").should be_true
    flib["myfilter"].should eq filter
  end

  it "fails to add unnamed feature" do
    flib = Crinja::Filter::Library.new register_defaults: false

    expect_raises(Exception, "cannot append unnamed feature") do
      flib << Crinja.filter() { "nothing" }
    end
  end
end
