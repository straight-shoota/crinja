require "./spec_helper.cr"

describe Crinja::Operator do
  describe Crinja::Operator::Library do
    it "has default operators registered" do
      library = Crinja::Operator::Library.new

      library.keys.should eq ["+", "-", "/", "//", "%", "*", "**", "~", "==", "!=", ">", ">=", "<", "<=", "and", "or", "not"]
    end

    it "should have + operator" do
      library = Crinja::Operator::Library.new
      library.has_key?("+").should be_true
    end

    it "plus operator is valid" do
      library = Crinja::Operator::Library.new(false)
      plus = Crinja::Operator::Plus.new
      library << plus
    end
  end
end
