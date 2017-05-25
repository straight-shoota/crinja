require "../spec_helper"

class User
  include Crinja::PyObject

  getter username

  def initialize(@username : String)
  end

  getattr
end

describe Crinja::Filter do
  describe "lowercase" do
    it "lowercases mixed case string" do
      evaluate_statement(%("Hello World" | lower)).should eq("hello world")
    end
    it "lowercases mixed case string" do
      evaluate_statement(%("hello world" | lower)).should eq("hello world")
    end
  end

  describe "uppercase" do
    it "uppercases mixed case string" do
      evaluate_statement(%("Hello World" | upper)).should eq("HELLO WORLD")
    end
    it "uppercases mixed case string" do
      evaluate_statement(%("hello world" | upper)).should eq("HELLO WORLD")
    end
  end

  describe "capitalize" do
    it "capitalizes" do
      evaluate_statement(%("foo bar"|capitalize)).should eq "Foo bar"
    end
  end

  describe "center" do
    it "centers" do
      evaluate_statement(%("foo"|center(9))).should eq "   foo   "
    end
  end

  describe "default" do
    it "retuns default for missing" do
      evaluate_statement(%(missing|default('no'))).should eq "no"
    end

    it "does not overwrite false" do
      evaluate_statement(%(false|default('no'))).should eq "false"
    end

    it "overwrites false if boolean=true" do
      evaluate_statement(%(false|default('no', true))).should eq "no"
    end

    it "does not overwrite given" do
      evaluate_statement(%(given|default('no')), {"given" => "yes"}).should eq "yes"
    end

    it "recognizes short-form `d`" do
      evaluate_statement(%(missing|d(false))).should eq "false"
    end
  end

  describe "dictsort" do
    pending "sorts" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_statement(%(foo|dictsort), bindings).should eq %([("aa", 0), ("AB", 3), ("b", 1), ("c", 2)])
    end

    pending "sorts caseinsensitive" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_statement(%(foo|dictsort(true)), bindings).should eq %([("AB", 3), ("aa", 0), ("b", 1), ("c", 2)])
    end

    pending "sorts by value" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_statement(%(foo|dictsort(false, "value")), bindings).should eq %([("aa", 0), ("b", 1), ("c", 2), ("AB", 3)])
    end
  end

  describe "list" do
    it "retuns array" do
      evaluate_statement(%([1, 2] | list)).should eq "[1, 2]"
    end
    it "splits string" do
      evaluate_statement(%("abc" | list)).should eq %(["a", "b", "c"])
    end
    it "fails for number" do
      expect_raises(Crinja::TypeError) do
        evaluate_statement(%(1 | list))
      end
    end
  end

  describe "batch" do
    it "batches" do
      evaluate_statement(%(foo|batch(3)|list), {"foo" => (0..9)}).should eq "[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]"
    end

    it "batches with fill" do
      evaluate_statement(%(foo|batch(3, "X")|list), {"foo" => (0..9)}).should eq %([[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, "X", "X"]])
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
      evaluate_statement(%(foo|slice(3)|list), {"foo" => (0..9)}).should eq "[[0, 1, 2, 3], [4, 5, 6], [7, 8, 9]]"
    end

    it "slices with fill" do
      evaluate_statement(%(foo|slice(3, "X")|list), {"foo" => (0..9)}).should eq %([[0, 1, 2, 3], [4, 5, 6, "X"], [7, 8, 9, "X"]])
    end
  end

  describe "striptags" do
    it "strips tags" do
      html = %(  <p>just a small   \n <a href="#">example</a> link</p>\n<p>to a webpage</p> <!-- <p>and some commented stuff</p> -->)
      evaluate_statement(%(foo|striptags), {"foo" => html}).should eq "just a small example link to a webpage"
    end
  end

  describe "filesizeformat" do
    it do
      evaluate_statement(%(100|filesizeformat)).should eq "100 Bytes"
      evaluate_statement(%(1000|filesizeformat)).should eq "1.0 kB"
      evaluate_statement(%(1000000|filesizeformat)).should eq "1.0 MB"
      evaluate_statement(%(1000000000|filesizeformat)).should eq "1.0 GB"
      evaluate_statement(%(1000000000000|filesizeformat)).should eq "1.0 TB"
      evaluate_statement(%(100|filesizeformat(true))).should eq "100 Bytes"
      evaluate_statement(%(1000000|filesizeformat(true))).should eq "976.6 KiB"
      evaluate_statement(%(1000000000|filesizeformat(true))).should eq "953.7 MiB"
      evaluate_statement(%(1000000000000|filesizeformat(true))).should eq "931.3 GiB"
    end

    it "issue59" do
      evaluate_statement(%(300|filesizeformat)).should eq "300 Bytes"
      evaluate_statement(%(3000|filesizeformat)).should eq "3.0 kB"
      evaluate_statement(%(3000000|filesizeformat)).should eq "3.0 MB"
      evaluate_statement(%(3000000000|filesizeformat)).should eq "3.0 GB"
      evaluate_statement(%(3000000000000|filesizeformat)).should eq "3.0 TB"
      evaluate_statement(%(300|filesizeformat(true))).should eq "300 Bytes"
      evaluate_statement(%(3000|filesizeformat(true))).should eq "2.9 KiB"
      evaluate_statement(%(3000000|filesizeformat(true))).should eq "2.9 MiB"
    end
  end

  describe "first" do
    it "range" do
      evaluate_statement(%(foo|first), {"foo" => (0..9)}).should eq "0"
    end
    it "string" do
      evaluate_statement(%("foo"|first)).should eq "f"
    end
  end

  describe "float" do
    it do
      evaluate_statement(%("42"|float)).should eq "42.0"
      evaluate_statement(%("ajsghasjgd"|float)).should eq "0.0"
      evaluate_statement(%("32.32"|float)).should eq "32.32"
    end
  end

  describe "format" do
    it do
      evaluate_statement(%("%s|%s"|format("a", "b"))).should eq "a|b"
    end
  end

  describe "indent" do
    it do
      text = ([(["foo", "bar"] * 2).join(" ")] * 2).join "\n"
      evaluate_statement(%(foo|indent(2)), {"foo" => text}).should eq "foo bar foo bar\n  foo bar foo bar"
      evaluate_statement(%(foo|indent(2, true)), {"foo" => text}).should eq "  foo bar foo bar\n  foo bar foo bar"
    end
  end

  describe "int" do
    it "base-16" do
      evaluate_statement(%("0x4d32"|int(0, 16))).should eq "19762"
    end
    it "base-16-overwrite" do
      evaluate_statement(%("0x4d32"|int(0, 8))).should eq "19762"
    end
    it "base-8" do
      evaluate_statement(%("011"|int(0, 8))).should eq "9"
    end
    it "custom-fallback" do
      evaluate_statement(%(""|int(5))).should eq "5"
    end
    it "float" do
      evaluate_statement(%(3.52|int)).should eq "3"
    end
    it "force-fallback" do
      evaluate_statement(%(""|int)).should eq "0"
    end
    it "integer" do
      evaluate_statement(%(3|int)).should eq "3"
    end
    it "string" do
      evaluate_statement(%("3.52"|int)).should eq "3"
    end
  end

  describe "join" do
    it "join" do
      evaluate_statement(%( [1, 2, 3]|join("|") )).should eq "1|2|3"
    end

    it "joins with autoescae" do
      evaluate_statement(%( ["<foo>", "<span>foo</span>"|safe]|join )).should eq "&lt;foo&gt;<span>foo</span>"
    end

    it "join_attribute" do
      evaluate_statement(%( users|join(', ', 'username') ), {"users" => [User.new("foo"), User.new("bar")]}).should eq "foo, bar"
    end
  end

  describe "length" do
    it "array" do
      evaluate_statement(%([1, 2, 3, 4]|length)).should eq "4"
    end
    it "number" do
      expect_raises(TypeError) do
        evaluate_statement(%(1234|length)).should eq ""
      end
    end
    it "object" do
      evaluate_statement(%({ a: 1, b: 2, c: 3, d: 4 }|length)).should eq "4"
    end
    it "number" do
      evaluate_statement(%('1234'|length)).should eq "4"
    end
  end

  describe "abs" do
    it "works with integer" do
      evaluate_statement(%(1 | abs)).should eq("1")
    end

    it "works with float" do
      evaluate_statement(%(-12.5 | abs)).should eq("12.5")
    end

    it "fails with string" do
      expect_raises(Crinja::InvalidArgumentException) do
        evaluate_statement(%("1" | abs))
      end
    end
  end

  describe "safe" do
    it "safe" do
      evaluate_statement(%("<div>foo</div>"|safe), autoescape: true).should eq "<div>foo</div>"
    end

    it "unsafe" do
      evaluate_statement(%("<div>foo</div>"), autoescape: true).should eq "&lt;div&gt;foo&lt;/div&gt;"
    end
  end
end
