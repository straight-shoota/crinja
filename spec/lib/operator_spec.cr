require "../spec_helper.cr"

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

    it "calc /" do
      render("{{ 15/3 }}").should eq "5.0"
    end
  end

  describe "==" do
    it { evaluate_expression(%([1, 2] == [1, 2, 3])).should eq "false" }
    it { evaluate_expression(%([1, 3] == [1, 3])).should eq "true" }
    it { evaluate_expression(%([1, 2] == 2)).should eq "false" }
    it { evaluate_expression(%(true == 2)).should eq "false" }
    it { evaluate_expression(%(1 == false)).should eq "false" }
    it { evaluate_expression(%({ foo: bar } == 2)).should eq "false" }
    it { evaluate_expression(%(1 == 2)).should eq "false" }
    it { evaluate_expression(%(2 == 2)).should eq "true" }
    it { evaluate_expression(%("a" == "b")).should eq "false" }
    it { evaluate_expression(%("b" == "b")).should eq "true" }
  end
  describe "!=" do
    it { evaluate_expression(%([1, 2] != [1, 2, 3])).should eq "true" }
    it { evaluate_expression(%([1, 3] != [1, 3])).should eq "false" }
    it { evaluate_expression(%([1, 2] != 2)).should eq "true" }
    it { evaluate_expression(%(true != 2)).should eq "true" }
    it { evaluate_expression(%(1 != true)).should eq "true" }
    it { evaluate_expression(%({ foo: bar } != 2)).should eq "true" }
    it { evaluate_expression(%(1 != 2)).should eq "true" }
    it { evaluate_expression(%(2 != 2)).should eq "false" }
    it { evaluate_expression(%("a" != "b")).should eq "true" }
    it { evaluate_expression(%("b" != "b")).should eq "false" }
  end

  describe "comparators" do
    describe ">" do
      it { evaluate_expression(%([1, 2] > [1, 2])).should eq "false" }
      it { evaluate_expression(%([1, 2] > [1, 2, 3])).should eq "false" }
      it { evaluate_expression(%([1, 3] > [1, 2, 3])).should eq "true" }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%([1, 2] > 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(true > 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(1 > false)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%({ foo: bar } > 2)) } }
      it { evaluate_expression(%(1 > 1)).should eq "false" }
      it { evaluate_expression(%(1 > 2)).should eq "false" }
      it { evaluate_expression(%(2 > 1)).should eq "true" }
      it { evaluate_expression(%("a" > "a")).should eq "false" }
      it { evaluate_expression(%("a" > "b")).should eq "false" }
      it { evaluate_expression(%("b" > "a")).should eq "true" }
    end
    describe ">=" do
      it { evaluate_expression(%([1, 2] >= [1, 2])).should eq "true" }
      it { evaluate_expression(%([1, 2] >= [1, 2, 3])).should eq "false" }
      it { evaluate_expression(%([1, 3] >= [1, 2, 3])).should eq "true" }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%([1, 2] >= 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(true >= 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(1 >= false)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%({ foo: bar } >= 2)) } }
      it { evaluate_expression(%(1 >= 1)).should eq "true" }
      it { evaluate_expression(%(1 >= 2)).should eq "false" }
      it { evaluate_expression(%(2 >= 1)).should eq "true" }
      it { evaluate_expression(%("a" >= "a")).should eq "true" }
      it { evaluate_expression(%("a" >= "b")).should eq "false" }
      it { evaluate_expression(%("b" >= "a")).should eq "true" }
    end
    describe "<=" do
      it { evaluate_expression(%([1, 2] <= [1, 2])).should eq "true" }
      it { evaluate_expression(%([1, 2] <= [1, 2, 3])).should eq "true" }
      it { evaluate_expression(%([1, 3] <= [1, 2, 3])).should eq "false" }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%([1, 2] <= 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(true <= 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(1 <= false)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%({ foo: bar } <= 2)) } }
      it { evaluate_expression(%(1 <= 1)).should eq "true" }
      it { evaluate_expression(%(1 <= 2)).should eq "true" }
      it { evaluate_expression(%(2 <= 1)).should eq "false" }
      it { evaluate_expression(%("a" <= "a")).should eq "true" }
      it { evaluate_expression(%("a" <= "b")).should eq "true" }
      it { evaluate_expression(%("b" <= "a")).should eq "false" }
    end
    describe "<" do
      it { evaluate_expression(%([1, 2] < [1, 2])).should eq "false" }
      it { evaluate_expression(%([1, 2] < [1, 2, 3])).should eq "true" }
      it { evaluate_expression(%([1, 3] < [1, 2, 3])).should eq "false" }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%([1, 2] < 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(true < 2)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%(1 < false)) } }
      it { expect_raises(Crinja::TypeError) { evaluate_expression(%({ foo: bar } < 2)) } }
      it { evaluate_expression(%(1 < 1)).should eq "false" }
      it { evaluate_expression(%(1 < 2)).should eq "true" }
      it { evaluate_expression(%(2 < 1)).should eq "false" }
      it { evaluate_expression(%("a" < "a")).should eq "false" }
      it { evaluate_expression(%("a" < "b")).should eq "true" }
      it { evaluate_expression(%("b" < "a")).should eq "false" }
    end
    describe "~" do
      pending { evaluate_expression(%("b" ~ "a")).should eq "ba" }
    end
  end
end
