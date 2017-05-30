require "../spec_helper"

describe Crinja::Operator do
  describe "+" do
    it "concatenates two strings" do
      evaluate_expression("'a' + 'b'").should eq("ab")
    end
    it "concatenates two arrays" do
      evaluate_expression("['a'] + ['b']").should eq(%(["a", "b"]))
    end
  end

  describe "-" do
    it "subtracts two integers" do
      evaluate_expression("1 - 3").should eq("-2")
    end

    it "subtracts integer from float" do
      evaluate_expression("4.5 - 2").should eq("2.5")
    end

    it "fails to subtract string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%(42 - "a"))
      end
    end
  end

  describe "/" do
    it "divides two integers" do
      evaluate_expression("4 / 2").should eq("2.0")
    end
    it "divides integer by float" do
      evaluate_expression("2 / 1.0").should eq("2.0")
    end
    it "divides two floats" do
      evaluate_expression("1.0 / 2.0").should eq("0.5")
    end
    it "fails to divde string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%(42 / "a"))
      end
    end
  end

  describe "//" do
    it "int divides two integers" do
      evaluate_expression("4 // 2").should eq("2")
    end
    it "int divides integer by float" do
      evaluate_expression("20 // 7.0").should eq("2")
    end
    it "int divides two floats" do
      evaluate_expression("1.0 // 2.0").should eq("0")
    end
    it "fails to int divde string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%(42 // "a"))
      end
    end
  end

  describe "%" do
    it "modulo two integers" do
      evaluate_expression("11 % 7").should eq("4")
    end
    it "modulo integer by float" do
      evaluate_expression("5 % 1.5").should eq("0")
    end
    it "modulo two floats" do
      evaluate_expression("1.0 % 2.0").should eq("1")
    end
    it "fails to modulo string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%(42 % "a"))
      end
    end
  end

  describe "*" do
    it "multiplies two integers" do
      evaluate_expression("2 * 3 ").should eq("6")
    end
    it "multiplies integer by float" do
      evaluate_expression("20 * 7.0 ").should eq("140.0")
    end
    it "multiplies two floats" do
      evaluate_expression("1.0 * 2.0 ").should eq("2.0")
    end
    it "fails to multiply string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%(42 * "a"))
      end
    end
  end

  describe "**" do
    it "raises two integers" do
      evaluate_expression("2 ** 3").should eq("8")
    end
    it "raises integer by float" do
      evaluate_expression("2 ** -1").should eq("0.5")
    end
    it "raises two floats" do
      evaluate_expression("4.0 ** 0.5").should eq("2.0")
    end
    it "fails to raise string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%(42 ** "a"))
      end
    end
  end

  describe "and" do
    it "works" do
      evaluate_expression("true and true").should eq("true")
    end
    it "works" do
      evaluate_expression("1 and 1").should eq("true")
    end
    it "works" do
      evaluate_expression("true and none").should eq("false")
    end
  end
end
