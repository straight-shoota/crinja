require "../spec_helper"

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

  it "defined" do
    render(%({{ missing is defined }}|{{ true is defined }})).should eq "false|true"
  end

  it "even" do
    render(%({{ 1 is even }}|{{ 2 is even }})).should eq "false|true"
  end

  it "odd" do
    render(%({{ 1 is odd }}|{{ 2 is odd }})).should eq "true|false"
  end

  it "lower" do
    render(%({{ "foo" is lower }}|{{ "FOO" is lower }})).should eq "true|false"
  end

  it "upper" do
    render(%({{ "FOO" is upper }}|{{ "foo" is upper }})).should eq "true|false"
  end

  it "equalto" do
    render(
      %({{ foo is equalto 12 }}|{{ foo is equalto 0 }}|{{ foo is equalto (3 * 4) }}|) \
      %({{ bar is equalto "baz" }}|{{ bar is equalto "zab" }}|{{ bar is equalto ("ba" + "z") }}|) \
      %({{ bar is equalto bar }}|{{ bar is equalto foo }}),
      {:foo => 12, :bar => "baz"}).should eq "true|false|true|true|false|true|true|false"
  end

  it "sequence" do
    render(%({{ [1, 2, 3] is sequence }}|{{ "foo" is sequence }}|{{ 42 is sequence }})).should eq "true|true|false"
  end

  it "sameas" do
    render(%({{ foo is sameas false }}|{{ 0 is sameas false }}), {:foo => false}).should eq "true|false"
  end

  it "parses test correctly" do
    evaluate_statement(%((10 ** 100) is number)).should eq "true"
  end

  it "parses range as function" do
    evaluate_statement(%(range is callable)).should eq "true"
  end

  # TODO: Implementation of complex numbers?
  it "typechecks" do
    render(<<-'TPL'
      {{ 42 is undefined }}
      {{ 42 is defined }}
      {{ 42 is none }}
      {{ none is none }}
      {{ 42 is number }}
      {{ 42 is string }}
      {{ "foo" is string }}
      {{ "foo" is sequence }}
      {{ [1] is sequence }}
      {{ range is callable }}
      {{ 42 is callable }}
      {{ range(5) is iterable }}
      {{ {} is mapping }}
      {{ mydict is mapping }}
      {{ [] is mapping }}
      {{ 10 is number }}
      {{ (10 ** 100) is number }}
      {{ 3.14159 is number }}
      {{ complex is number }}
      TPL, {:mydict => Hash(String, Crinja::Type).new, :complex => 0.0}).split.should eq [
      "false", "true", "false", "true", "true", "false",
      "true", "true", "true", "true", "false", "true",
      "true", "true", "false", "true", "true", "true", "true",
    ]
  end

  it "greaterthan" do
    render(%({{ 1 is greaterthan 0 }}|{{ 0 is greaterthan 1 }})).should eq "true|false"
  end

  it "lessthan" do
    render(%({{ 0 is lessthan 1 }}|{{ 1 is lessthan 0 }})).should eq "true|false"
  end

  it "no_paren_for_arg1" do
    evaluate_statement(%(foo is sameas none), {:foo => nil}).should eq "true"
  end

  it "escaped" do
    render(%({{ x is escaped }}|{{ y is escaped }}), {:x => "foo", :y => Crinja::SafeString.escape("foo")}, autoescape: true).should eq "false|true"
  end

  it "in" do
    render(
      %({{ "o" is in "foo" }}|{{ "foo" is in "foo" }}|{{ "b" is in "foo" }}|) \
      %({{ 1 is in [1, 2] }}|) \
      %({{ 3 is in [1, 2] }}|{{ "foo" is in {"foo": 1} }}|{{ "baz" is in {"bar": 1} }}) # %({{ 1 is in ((1, 2)) }}|{{ 3 is in ((1, 2)) }}|

    ).should eq("true|true|false|" \
                "true|false|true|false")
    # true|false|)
  end

  it "error in plus list" do
    evaluate_statement(%(1 is in [1, 2])).should eq "true"
  end

  describe Crinja::Test::Divisibleby do
    it "should be true" do
      evaluate_statement(%(56 is divisibleby(7))).should eq("true")
    end
    it "should be false" do
      evaluate_statement(%(57 is divisibleby(7))).should eq("false")
    end
  end
end
