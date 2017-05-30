require "../spec_helper"

# Tests based on https://github.com/pallets/jinja/blob/d905cf0b6c6121d900ea384f72970b862c879bc7/tests/test_tests.py

describe Crinja::Test do
  describe "callable" do
    it "should find callable" do
      evaluate_expression(%(foo is callable), {"foo" => Crinja.function() { }}).should eq("true")
    end

    it "should find not callable" do
      evaluate_expression(%(foo is callable), {"foo" => "bar"}).should eq("false")
    end
  end

  it "defined" do
    render(%({{ missing is defined }}|{{ true is defined }})).should eq "false|true"
  end

  it "not" do
    render(%({{ missing is not defined }}|{{ true is not defined }})).should eq "true|false"
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
    evaluate_expression(%((10 ** 100) is number)).should eq "true"
  end

  describe "typechecks" do
    it { evaluate_expression(%( 42 is undefined )).should eq "false" }
    it { evaluate_expression(%( 42 is defined )).should eq "true" }
    it { evaluate_expression(%( 42 is none )).should eq "false" }
    it { evaluate_expression(%( none is none )).should eq "true" }
    it { evaluate_expression(%( 42 is number )).should eq "true" }
    it { evaluate_expression(%( 42 is string )).should eq "false" }
    it { evaluate_expression(%( "foo" is string )).should eq "true" }
    it { evaluate_expression(%( "foo" is sequence )).should eq "true" }
    it { evaluate_expression(%( [1] is sequence )).should eq "true" }
    it { evaluate_expression(%( range is callable )).should eq "true" }
    it { evaluate_expression(%( 42 is callable )).should eq "false" }
    it { evaluate_expression(%( range(5) is iterable )).should eq "true" }
    it { evaluate_expression(%( {} is mapping )).should eq "true" }
    it { evaluate_expression(%( mydict is mapping ), {:mydict => Hash(String, Crinja::Type).new}).should eq "true" }
    it { evaluate_expression(%( [] is mapping )).should eq "false" }
    it { evaluate_expression(%( 10 is number )).should eq "true" }
    it { evaluate_expression(%( (10 ** 100) is number )).should eq "true" }
    it { evaluate_expression(%( 3.14159 is number )).should eq "true" }
  end

  # TODO: Implementation of complex numbers?
  pending "complex number" do
    evaluate_expression(%( complex is number ), {:complex => 0.0}).should eq "true"
  end

  it "greaterthan" do
    render(%({{ 1 is greaterthan 0 }}|{{ 0 is greaterthan 1 }})).should eq "true|false"
  end

  it "lessthan" do
    render(%({{ 0 is lessthan 1 }}|{{ 1 is lessthan 0 }})).should eq "true|false"
  end

  it "no_paren_for_arg1" do
    evaluate_expression(%(foo is sameas none), {:foo => nil}).should eq "true"
  end

  it "escaped" do
    render(%({{ x is escaped }}|{{ y is escaped }}), {:x => "foo", :y => Crinja::SafeString.escape("foo")}, autoescape: true).should eq "false|true"
  end

  it "in" do
    render(
      %({{ "o" is in "foo" }}|{{ "foo" is in "foo" }}|{{ "b" is in "foo" }}|) \
      %({{ 1 is in [1, 2] }}|) \
      %({{ 3 is in [1, 2] }}|{{ "foo" is in {"foo": 1} }}|{{ "baz" is in {"bar": 1} }}|) \
      %({{ 1 is in ((1, 2)) }}|{{ 3 is in ((1, 2)) }})
    ).should eq("true|true|false|" \
                "true|false|true|false|" \
                "true|false")
  end

  it "error in plus list" do
    evaluate_expression(%(1 is in [1, 2])).should eq "true"
  end

  describe "divisibleby" do
    it "should be true" do
      evaluate_expression(%(56 is divisibleby(7))).should eq("true")
    end
    it "should be false" do
      evaluate_expression(%(57 is divisibleby(7))).should eq("false")
    end
  end

  it "test_custom_test" do
    items = [] of Tuple(String, String)
    matching = Crinja.test({x: nil}) { items << {target.as_s, x.as_s}; false }

    env = Crinja::Environment.new
    env.tests["matching"] = matching
    tmpl = env.from_string("{{ ('us-west-1' is matching '(us-east-1|ap-northeast-1)') " \
                           "or 'stage' is matching '(dev|stage)' }}"
    )
    tmpl.render.should eq "false"
    items.should eq [{"us-west-1", "(us-east-1|ap-northeast-1)"},
                     {"stage", "(dev|stage)"}]
  end
end
