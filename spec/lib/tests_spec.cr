require "./spec_helper.cr"
require "../statement/spec_helper"

class TestFunction
  include Crinja::Callable

  def call(arguments : Crinja::Callable::Arguments) : Crinja::Type
  end
end

describe Crinja::Test do
  describe Crinja::Test::Callable do
    it "should find callable" do
      evaluate_statement(%(foo is callable), {"foo" => TestFunction.new}).should eq("true")
    end

    it "should find not callable" do
      evaluate_statement(%(foo is callable), {"foo" => "bar"}).should eq("false")
    end
  end

  describe Crinja::Test::Defined do
    it "sould be defined" do
      evaluate_statement(%(foo is defined), {"foo" => nil}).should eq("true")
    end
    it "sould be undefined" do
      evaluate_statement(%(foo is defined)).should eq("false")
    end
  end

  describe Crinja::Test::Even do
    it "should be true vor even" do
      evaluate_statement(%(42 is even)).should eq("true")
    end

    it "should be false for odd" do
      evaluate_statement(%(41 is even)).should eq("false")
    end
  end

  describe Crinja::Test::Odd do
    it "should be true vor even" do
      evaluate_statement(%(42 is odd)).should eq("false")
    end

    it "should be false for odd" do
      evaluate_statement(%(41 is odd)).should eq("true")
    end
  end
end
