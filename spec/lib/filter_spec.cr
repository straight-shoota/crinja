require "../spec_helper"

private class User
  include Crinja::PyObject

  getter username

  def initialize(@username : String)
  end

  getattr
end

describe Crinja::Filter do
  describe "lowercase" do
    it "lowercases mixed case string" do
      evaluate_expression(%("Hello World" | lower)).should eq("hello world")
    end
    it "lowercases mixed case string" do
      evaluate_expression(%("hello world" | lower)).should eq("hello world")
    end
  end

  describe "uppercase" do
    it "uppercases mixed case string" do
      evaluate_expression(%("Hello World" | upper)).should eq("HELLO WORLD")
    end
    it "uppercases mixed case string" do
      evaluate_expression(%("hello world" | upper)).should eq("HELLO WORLD")
    end
  end

  describe "capitalize" do
    it "capitalizes" do
      evaluate_expression(%("foo bar"|capitalize)).should eq "Foo bar"
    end
  end

  describe "center" do
    it "centers" do
      evaluate_expression(%("foo"|center(9))).should eq "   foo   "
    end
  end

  describe "default" do
    it "retuns default for missing" do
      evaluate_expression(%(missing|default('no'))).should eq "no"
    end

    it "does not overwrite false" do
      evaluate_expression(%(false|default('no'))).should eq "false"
    end

    it "overwrites false if boolean=true" do
      evaluate_expression(%(false|default('no', true))).should eq "no"
    end

    it "does not overwrite given" do
      evaluate_expression(%(given|default('no')), {"given" => "yes"}).should eq "yes"
    end

    it "recognizes short-form `d`" do
      evaluate_expression(%(missing|d(false))).should eq "false"
    end
  end

  describe "dictsort" do
    pending "sorts" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_expression(%(foo|dictsort), bindings).should eq %([("aa", 0), ("AB", 3), ("b", 1), ("c", 2)])
    end

    pending "sorts caseinsensitive" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_expression(%(foo|dictsort(true)), bindings).should eq %([("AB", 3), ("aa", 0), ("b", 1), ("c", 2)])
    end

    pending "sorts by value" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_expression(%(foo|dictsort(false, "value")), bindings).should eq %([("aa", 0), ("b", 1), ("c", 2), ("AB", 3)])
    end
  end

  describe "list" do
    it "retuns array" do
      evaluate_expression(%([1, 2] | list)).should eq "[1, 2]"
    end
    it "splits string" do
      evaluate_expression(%("abc" | list)).should eq %(["a", "b", "c"])
    end
    it "fails for number" do
      expect_raises(Crinja::TypeError) do
        evaluate_expression(%(1 | list))
      end
    end
  end

  describe "batch" do
    it "batches" do
      evaluate_expression(%(foo|batch(3)|list), {"foo" => (0..9)}).should eq "[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]"
    end

    it "batches with fill" do
      evaluate_expression(%(foo|batch(3, "X")|list), {"foo" => (0..9)}).should eq %([[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, "X", "X"]])
    end

    it "size-and-fill" do
      render(<<-'TPL'
        {% for row in items|batch(3, '-') -%}
        {% for column in row %} {{ column }} {% endfor %} |
        {% endfor %}
        TPL, {items: ["a", "b", "c", "d", "e", "f", "g"]}).should eq " a  b  c  |\n d  e  f  |\n g  -  -  |\n"
    end

    it "size-only" do
      render(<<-'TPL'
        {% for row in items|batch(3) -%}
        {% for column in row %} {{ column }} {% endfor %} |
        {% endfor %}
        TPL, {items: ["a", "b", "c", "d", "e", "f", "g"]}).should eq " a  b  c  |\n d  e  f  |\n g  |\n"
    end
  end

  describe "slice" do
    it "slices" do
      evaluate_expression(%(foo|slice(3)|list), {"foo" => (0..9)}).should eq "[[0, 1, 2, 3], [4, 5, 6], [7, 8, 9]]"
    end

    it "slices with fill" do
      evaluate_expression(%(foo|slice(3, "X")|list), {"foo" => (0..9)}).should eq %([[0, 1, 2, 3], [4, 5, 6, "X"], [7, 8, 9, "X"]])
    end
  end

  # NOTE: Jinja2 encodes '"' as '&#34;' instead of '&quot;'
  describe "escape" do
    evaluate_expression(%('<">&'|escape)).should eq "&lt;&quot;&gt;&amp;"
  end

  describe "striptags" do
    it "strips tags" do
      html = %(  <p>just a small   \n <a href="#">example</a> link</p>\n<p>to a webpage</p> <!-- <p>and some commented stuff</p> -->)
      evaluate_expression(%(foo|striptags), {"foo" => html}).should eq "just a small example link to a webpage"
    end
  end

  describe "filesizeformat" do
    it do
      evaluate_expression(%(100|filesizeformat)).should eq "100 Bytes"
      evaluate_expression(%(1000|filesizeformat)).should eq "1.0 kB"
      evaluate_expression(%(1000000|filesizeformat)).should eq "1.0 MB"
      evaluate_expression(%(1000000000|filesizeformat)).should eq "1.0 GB"
      evaluate_expression(%(1000000000000|filesizeformat)).should eq "1.0 TB"
      evaluate_expression(%(100|filesizeformat(true))).should eq "100 Bytes"
      evaluate_expression(%(1000000|filesizeformat(true))).should eq "976.6 KiB"
      evaluate_expression(%(1000000000|filesizeformat(true))).should eq "953.7 MiB"
      evaluate_expression(%(1000000000000|filesizeformat(true))).should eq "931.3 GiB"
    end

    it "issue59" do
      evaluate_expression(%(300|filesizeformat)).should eq "300 Bytes"
      evaluate_expression(%(3000|filesizeformat)).should eq "3.0 kB"
      evaluate_expression(%(3000000|filesizeformat)).should eq "3.0 MB"
      evaluate_expression(%(3000000000|filesizeformat)).should eq "3.0 GB"
      evaluate_expression(%(3000000000000|filesizeformat)).should eq "3.0 TB"
      evaluate_expression(%(300|filesizeformat(true))).should eq "300 Bytes"
      evaluate_expression(%(3000|filesizeformat(true))).should eq "2.9 KiB"
      evaluate_expression(%(3000000|filesizeformat(true))).should eq "2.9 MiB"
    end
  end

  describe "first" do
    it "range" do
      evaluate_expression(%(foo|first), {"foo" => (0..9)}).should eq "0"
    end
    it "string" do
      evaluate_expression(%("foo"|first)).should eq "f"
    end
  end

  describe "float" do
    it do
      evaluate_expression(%("42"|float)).should eq "42.0"
      evaluate_expression(%("ajsghasjgd"|float)).should eq "0.0"
      evaluate_expression(%("32.32"|float)).should eq "32.32"
    end
  end

  describe "format" do
    it do
      evaluate_expression(%("%s|%s"|format("a", "b"))).should eq "a|b"
    end
  end

  describe "indent" do
    it do
      text = ([(["foo", "bar"] * 2).join(" ")] * 2).join "\n"
      evaluate_expression(%(foo|indent(2)), {"foo" => text}).should eq "foo bar foo bar\n  foo bar foo bar"
      evaluate_expression(%(foo|indent(2, true)), {"foo" => text}).should eq "  foo bar foo bar\n  foo bar foo bar"
    end
  end

  describe "int" do
    it "base-16" do
      evaluate_expression(%("0x4d32"|int(0, 16))).should eq "19762"
    end
    it "base-16-overwrite" do
      evaluate_expression(%("0x4d32"|int(0, 8))).should eq "19762"
    end
    it "base-8" do
      evaluate_expression(%("011"|int(0, 8))).should eq "9"
    end
    it "custom-fallback" do
      evaluate_expression(%(""|int(5))).should eq "5"
    end
    it "float" do
      evaluate_expression(%(3.52|int)).should eq "3"
    end
    it "force-fallback" do
      evaluate_expression(%(""|int)).should eq "0"
    end
    it "integer" do
      evaluate_expression(%(3|int)).should eq "3"
    end
    it "string" do
      evaluate_expression(%("3.52"|int)).should eq "3"
    end
  end

  describe "join" do
    it "join" do
      evaluate_expression(%( [1, 2, 3]|join("|") )).should eq "1|2|3"
    end

    it "joins with autoescae" do
      evaluate_expression(%( ["<foo>", "<span>foo</span>"|safe]|join )).should eq "&lt;foo&gt;<span>foo</span>"
    end

    it "join_attribute" do
      evaluate_expression(%( users|join(', ', 'username') ), {"users" => [User.new("foo"), User.new("bar")]}).should eq "foo, bar"
    end
  end

  describe "last" do
    it "last" do
      evaluate_expression(%(foo|last), { foo: Range.new(0, 10, true)}).should eq "9"
    end
  end

  describe "length" do
    it "array" do
      evaluate_expression(%([1, 2, 3, 4]|length)).should eq "4"
    end
    it "number" do
      expect_raises(TypeError) do
        evaluate_expression(%(1234|length)).should eq ""
      end
    end
    it "object" do
      evaluate_expression(%({ a: 1, b: 2, c: 3, d: 4 }|length)).should eq "4"
    end
    it "number" do
      evaluate_expression(%('1234'|length)).should eq "4"
    end
  end

  describe "pprint" do
    it "pprint" do
      data = Range.new(0, 1000, true)
      evaluate_expression(%(data|pprint), { data: data }).should eq data.to_a.pretty_inspect
    end
  end

  it "random" do
    seq = Range.new(0, 100, true)
    10.times do
      evaluate_expression(%(seq|random), { seq: seq }).to_i.should be_in seq
    end
  end

  describe "reverse" do
    it "string" do
      evaluate_expression(%("foobar"|reverse)).should eq "raboof"
    end
    it "array" do
      evaluate_expression(%([1, 2, 3]|reverse|list)).should eq "[3, 2, 1]"
    end
  end

  describe "abs" do
    it "works with integer" do
      evaluate_expression(%(1 | abs)).should eq("1")
    end

    it "works with float" do
      evaluate_expression(%(-12.5 | abs)).should eq("12.5")
    end

    it "fails with string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_expression(%("1" | abs))
      end
    end
  end

  describe "safe" do
    it "safe" do
      evaluate_expression(%("<div>foo</div>"|safe), autoescape: true).should eq "<div>foo</div>"
    end

    it "unsafe" do
      evaluate_expression(%("<div>foo</div>"), autoescape: true).should eq "&lt;div&gt;foo&lt;/div&gt;"
    end
  end

  describe "attr" do
    it do
      evaluate_expression(%(data | attr("foo")), { data: { "foo" => "bar" } }).should eq "bar"
    end
    it do
      evaluate_expression(%(arr | attr(0)), { arr: ["bar"] }).should eq ""
    end
  end
end
