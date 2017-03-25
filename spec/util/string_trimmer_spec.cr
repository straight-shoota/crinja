require "spec"
require "../../src/crinja/util/string_trimmer"

describe Crinja::StringTrimmer do
  it "trims whitespace without linebreaks" do
    Crinja::StringTrimmer.trim("  \tfoo ").should eq("foo")
  end

  it "does not trim when there is no whitespace at beginning or end" do
    Crinja::StringTrimmer.trim("a  \t\nfoo  \n z").should eq("a  \t\nfoo  \n z")
  end

  it "trims whitespace on the same line at both ends" do
    Crinja::StringTrimmer.trim("  \t\nfoo  \n ").should eq("foo  ")
  end

  it "test" do
    Crinja::StringTrimmer.trim("\n        yay\n    ").should eq("        yay")
  end
end
