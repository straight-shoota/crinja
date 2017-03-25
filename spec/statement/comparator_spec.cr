require "./spec_helper"

describe Crinja::Operator do
  describe "==" do
    context "valid" do
      it "compares two strings" do
        evaluate_statement(%('a' == 'a')).should eq("true")
      end
      it "compares two arrays" do
        evaluate_statement(%(['a'] == ['a'])).should eq("true")
      end
    end
    context "invalid" do
      it "compares two strings" do
        evaluate_statement(%('a' == 'b')).should eq("false")
      end
      it "compares two arrays" do
        evaluate_statement(%(['a'] == ['b'])).should eq("false")
      end
    end
  end

  describe "!=" do
    context "valid" do
      it "compares two strings" do
        evaluate_statement(%('a' != 'b')).should eq("true")
      end
      it "compares two arrays" do
        evaluate_statement(%(['a'] != ['b'])).should eq("true")
      end
    end
    context "invalid" do
      it "compares two strings" do
        evaluate_statement(%('a' != 'a')).should eq("false")
      end
      it "compares two arrays" do
        evaluate_statement(%(['a'] != ['a'])).should eq("false")
      end
    end
  end
end
