require "spec"
require "../../src/crinja/util/string_trimmer"

describe Crinja::Util::StringTrimmer do
  it "trims whitespace without linebreaks" do
    Crinja::Util::StringTrimmer.trim("  \tfoo ").should eq("foo")
  end

  it "does not trim when there is no whitespace at beginning or end" do
    Crinja::Util::StringTrimmer.trim("a  \t\nfoo  \n z").should eq("a  \t\nfoo  \n z")
  end

  it "trims whitespace on the same line at both ends" do
    Crinja::Util::StringTrimmer.trim("  \t\nfoo  \n ").should eq("\nfoo  \n")
  end

  it "don't strip newslines" do
    Crinja::Util::StringTrimmer.trim("\n        yay\n    ").should eq("\n        yay\n")
  end

  it "strip newlines" do
    Crinja::Util::StringTrimmer.trim("\n        yay\n    ", true, true, true, true).should eq("        yay")
  end

  it "remove single newline from whitespace string" do
    Crinja::Util::StringTrimmer.trim("\n   ", true, true, true, false).should eq("")
  end

  it "remove single newline from whitespace string with trim_newline_" do
    Crinja::Util::StringTrimmer.trim("\n   ", true, true, true, true).should eq("")
  end
end
