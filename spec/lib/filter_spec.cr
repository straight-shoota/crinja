require "../spec_helper"

# These specs are derived from the original Jinja2 filter specs
# https://github.com/pallets/jinja/blob/bbe0a4174c2846487bef4328b309fddd8638da39/tests/test_filters.py

private class User
  include Crinja::PyObject

  getter username, is_active

  def initialize(@username : String, @is_active : Bool = true)
  end

  def to_s(io)
    io << username
  end

  getattr
end

private class IdUser
  include Crinja::PyObject

  getter id, name

  def initialize(@id : Int32, @name : String)
  end

  def to_s(io)
    io << name
  end

  getattr
end

private class Date
  include Crinja::PyObject
  getter day : Int32
  getter month : Int32
  getter year : Int32

  getattr

  def initialize(@day, @month, @year)
  end
end

private class Article
  include Crinja::PyObject
  getter title : String
  getter date : Date
  getattr

  def initialize(@title, *date)
    @date = Date.new(*date)
  end
end

describe Crinja::Filter do
  it "calling" do
    Crinja.new.call_filter("sum", [1, 2, 3]).should eq 6
  end

  it "capitalize" do
    evaluate_expression(%("foo bar"|capitalize)).should eq "Foo bar"
  end

  it "center" do
    evaluate_expression(%("foo"|center(9))).should eq "   foo   "
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
    it "sorts" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_expression(%(foo|dictsort), bindings).should eq %([('aa', 0), ('AB', 3), ('b', 1), ('c', 2)])
    end

    it "sorts caseinsensitive" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_expression(%(foo|dictsort(true)), bindings).should eq %([('AB', 3), ('aa', 0), ('b', 1), ('c', 2)])
    end

    it "sorts by value" do
      bindings = {"foo" => {"aa" => 0, "b" => 1, "c" => 2, "AB" => 3}}
      evaluate_expression(%(foo|dictsort(false, "value")), bindings).should eq %([('aa', 0), ('b', 1), ('c', 2), ('AB', 3)])
    end
  end

  describe "batch" do
    it "batches" do
      evaluate_expression(%(foo|batch(3)|list), {"foo" => (0..9)}).should eq "[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]"
    end

    it "batches with fill" do
      evaluate_expression(%(foo|batch(3, "X")|list), {"foo" => (0..9)}).should eq %([[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 'X', 'X']])
    end

    it "size-and-fill" do
      render(<<-'TPL',
        {% for row in items|batch(3, '-') -%}
        {% for column in row %} {{ column }} {% endfor %} |
        {% endfor %}
        TPL
        {items: ["a", "b", "c", "d", "e", "f", "g"]}).should eq " a  b  c  |\n d  e  f  |\n g  -  -  |\n"
    end

    it "size-only" do
      render(<<-'TPL',
        {% for row in items|batch(3) -%}
        {% for column in row %} {{ column }} {% endfor %} |
        {% endfor %}
        TPL
        {items: ["a", "b", "c", "d", "e", "f", "g"]}).should eq " a  b  c  |\n d  e  f  |\n g  |\n"
    end
  end

  describe "slice" do
    it "slices" do
      evaluate_expression(%(foo|slice(3)|list), {"foo" => (0..9)}).should eq "[[0, 1, 2, 3], [4, 5, 6], [7, 8, 9]]"
    end

    it "slices with fill" do
      evaluate_expression(%(foo|slice(3, "X")|list), {"foo" => (0..9)}).should eq %([[0, 1, 2, 3], [4, 5, 6, 'X'], [7, 8, 9, 'X']])
    end
  end

  # NOTE: Jinja2 encodes '"' as '&#34;' instead of '&quot;'
  it "escape" do
    evaluate_expression(%('<">&'|escape)).should eq "&lt;&quot;&gt;&amp;"
    evaluate_expression(%(x|escape), {x: Crinja::SafeString.new("<div />")}).should eq "<div />"
  end

  it "strips tags" do
    html = %(  <p>just a small   \n <a href="#">example</a> link</p>\n<p>to a webpage</p> <!-- <p>and some commented stuff</p> -->)
    evaluate_expression(%(foo|striptags), {"foo" => html}).should eq "just a small example link to a webpage"
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

  it "first" do
    evaluate_expression(%(foo|first), {"foo" => (0..9)}).should eq "0"
    evaluate_expression(%("foo"|first)).should eq "f"
  end

  it "float" do
    evaluate_expression(%("42"|float)).should eq "42.0"
    evaluate_expression(%("ajsghasjgd"|float)).should eq "0.0"
    evaluate_expression(%("32.32"|float)).should eq "32.32"
  end

  it "format" do
    evaluate_expression(%("%s|%s"|format("a", "b"))).should eq "a|b"
  end

  it "indent" do
    text = ([(["foo", "bar"] * 2).join(" ")] * 2).join "\n"
    evaluate_expression(%(foo|indent(2)), {"foo" => text}).should eq "foo bar foo bar\n  foo bar foo bar"
    evaluate_expression(%(foo|indent(2, true)), {"foo" => text}).should eq "  foo bar foo bar\n  foo bar foo bar"
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

    it "joins with autoescape" do
      evaluate_expression(%( ["<foo>", "<span>foo</span>"|safe]|join ), autoescape: true).should eq "&lt;foo&gt;<span>foo</span>"
    end

    it "join_attribute" do
      evaluate_expression(%( users|join(', ', 'username') ), {"users" => [User.new("foo"), User.new("bar")]}).should eq "foo, bar"
    end
  end

  it "last" do
    evaluate_expression(%(foo|last), {foo: Range.new(0, 10, true)}).should eq "9"
  end

  describe "length" do
    it "array" do
      evaluate_expression(%([1, 2, 3, 4]|length)).should eq "4"
    end
    it "number" do
      expect_raises(Crinja::TypeError) do
        evaluate_expression(%(1234|length)).should eq ""
      end
    end
    it "object" do
      evaluate_expression(%({ "a": 1, "b": 2, "c": 3, "d": 4 }|length)).should eq "4"
    end
    it "number" do
      evaluate_expression(%('1234'|length)).should eq "4"
    end
  end

  it "lower" do
    evaluate_expression(%("Hello World" | lower)).should eq("hello world")
    evaluate_expression(%("hello world" | lower)).should eq("hello world")
  end

  it "pprint" do
    data = Range.new(0, 1000, true)
    evaluate_expression(%(data|pprint), {data: data}).should eq data.to_a.pretty_inspect
  end

  it "random" do
    seq = Range.new(0, 100, true)
    10.times do
      evaluate_expression(%(seq|random), {seq: seq}).to_i.should be_in seq
    end
  end

  it "reverse" do
    evaluate_expression(%("foobar"|reverse)).should eq "raboof"
    evaluate_expression(%([1, 2, 3]|reverse|list)).should eq "[3, 2, 1]"
  end

  it "string" do
    list = [1, 2, 3, 4, 5]
    evaluate_expression(%(obj|string), {obj: list}).should eq list.to_s
  end

  describe "title" do
    it { evaluate_expression(%("foo bar"|title)).should eq "Foo Bar" }
    it { evaluate_expression(%("foo's bar"|title)).should eq "Foo's Bar" }
    it { evaluate_expression(%("foo   bar"|title)).should eq "Foo   Bar" }
    it { evaluate_expression(%("f bar f"|title)).should eq "F Bar F" }
    it { evaluate_expression(%("foo-bar"|title)).should eq "Foo-Bar" }
    it { evaluate_expression(%("foo\tbar"|title)).should eq "Foo\tBar" }
    it { evaluate_expression(%("FOO\tBAR"|title)).should eq "Foo\tBar" }
    it { evaluate_expression(%("foo (bar)"|title)).should eq "Foo (Bar)" }
    it { evaluate_expression(%("foo {bar}"|title)).should eq "Foo {Bar}" }
    it { evaluate_expression(%("foo [bar]"|title)).should eq "Foo [Bar]" }
    it { evaluate_expression(%("foo <bar>"|title)).should eq "Foo <Bar>" }

    it "from object" do
      evaluate_expression(%(data|title), {data: User.new("foo-bar")}).should eq "Foo-Bar"
    end
  end

  it "truncate" do
    evaluate_expression(%(data|truncate(15, true, ">>>")), {
      data:      "foobar baz bar" * 1000,
      smalldata: "foobar baz bar",
    }).should eq "foobar baz b>>>"
    evaluate_expression(%(data|truncate(15, false, ">>>")), {
      data:      "foobar baz bar" * 1000,
      smalldata: "foobar baz bar",
    }).should eq "foobar baz>>>"
    evaluate_expression(%(smalldata|truncate(15)), {
      data:      "foobar baz bar" * 1000,
      smalldata: "foobar baz bar",
    }).should eq "foobar baz bar"

    evaluate_expression(%("foo bar baz"|truncate(9))).should eq "foo bar baz"
    evaluate_expression(%("foo bar baz"|truncate(9, true))).should eq "foo bar baz"

    evaluate_expression(%("Joel is a slug"|truncate(7, true))).should eq "Joel..."
    evaluate_expression(%("Crystal"|truncate(5))).should eq "Cr..."
    evaluate_expression(%("Motorala"|truncate(length=4))).should eq "M..."
    evaluate_expression(%("Motorala"|truncate(length=6))).should eq "Motorala"
  end

  it "upper" do
    evaluate_expression(%("Hello World" | upper)).should eq("HELLO WORLD")
    evaluate_expression(%("hello world" | upper)).should eq("HELLO WORLD")
  end

  describe "urlize" do
    it "urlize" do
      evaluate_expression(%("foo http://www.example.com/ bar"|urlize)).should eq \
        %(foo <a href="http://www.example.com/" rel="noopener">) +
        %(http://www.example.com/</a> bar)
    end

    it "urlize rel policy" do
      env = Crinja.new
      env.policies["urlize.rel"] = Crinja::Value.new nil
      env.evaluate(%("foo http://www.example.com/ bar"|urlize)).should eq \
        %(foo <a href="http://www.example.com/">http://www.example.com/</a> bar)
    end

    it "urlize_target_parameter" do
      evaluate_expression(%("foo http://www.example.com/ bar"|urlize(target="_blank"))).should eq \
        %(foo <a href="http://www.example.com/" rel="noopener" target="_blank">) +
        %(http://www.example.com/</a> bar)
    end
  end

  it "wordcount" do
    evaluate_expression(%("foo bar baz"|wordcount)).should eq "3"
  end

  it "chaining" do
    evaluate_expression(%(['<foo>', '<bar>']|first|upper|escape)).should eq "&lt;FOO&gt;"
  end

  describe "sum" do
    it "sums" do
      evaluate_expression(%([1, 2, 3, 4, 5, 6]|sum)).should eq "21"
    end

    it "sums attribute" do
      values = [{"value" => 23}, {"value" => 1}, {"value" => 18}]
      evaluate_expression(%(values|sum('value')), {values: values}).should eq "42"
    end

    it "sums attributes nested" do
      values = [{"real": {"value" => 23}}, {"real": {"value" => 1}}, {"real": {"value" => 18}}]
      evaluate_expression(%(values|sum('real.value')), {values: values}).should eq "42"
    end

    it "sums attributes tuple" do
      values = {"foo" => 23, "bar" => 1, "baz" => 18}
      evaluate_expression(%(values|sum('1')), {values: values}).should eq "42"
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
      expect_raises(Crinja::Callable::ArgumentError) do
        evaluate_expression(%("1" | abs))
      end
    end
  end

  it "round" do
    evaluate_expression(%(2.7|round)).should eq "3.0"
    evaluate_expression(%(2.1|round)).should eq "2.0"
    evaluate_expression(%(2.1234|round(3, 'floor'))).should eq "2.123"
    evaluate_expression(%(2.1|round(0, 'ceil'))).should eq "3.0"
    evaluate_expression(%(2|round(0, 'ceil'))).should eq "2.0"

    evaluate_expression(%(21.3|round(-1))).should eq "20.0"
    evaluate_expression(%(21.3|round(-1, 'ceil'))).should eq "30.0"
    evaluate_expression(%(21.3|round(-1, 'floor'))).should eq "20.0"
  end

  it "xmlattr" do
    kvpairs = evaluate_expression(%({'foo': 42, 'bar': 23, 'fish': none, ) \
                                  %('spam': missing, 'blub:blub': '<?>'}|xmlattr)).split(' ')

    kvpairs.should contain %(foo="42")
    kvpairs.should contain %(bar="23")
    kvpairs.should contain %(blub:blub="&lt;?&gt;")
    kvpairs.size.should eq 4
  end

  describe "sort" do
    it do
      evaluate_expression(%([2, 3, 1]|sort)).should eq "[1, 2, 3]"
      evaluate_expression(%([2, 3, 1]|sort(true))).should eq "[3, 2, 1]"
      evaluate_expression(%(["c", "A", "b", "D"]|sort|join)).should eq "AbcD"
      evaluate_expression(%(["c", "A", "b", "D"]|sort(case_sensitive=true)|join)).should eq "ADbc"
      evaluate_expression(%(['foo', 'Bar', 'blah']|sort)).should eq %(['Bar', 'blah', 'foo'])
    end

    it "custom_sort" do
      users = [
        IdUser.new(3, "mike"),
        IdUser.new(1, "john"),
        IdUser.new(4, "mick"),
        IdUser.new(2, "jane"),
      ]
      evaluate_expression(%(users|sort(attribute='id')|join(",")), {users: users}).should eq "john,jane,mike,mick"
    end
  end

  describe "groupby" do
    it "basic" do
      render(<<-'TPL'
        {%- for grouper, list in [{'foo': 1, 'bar': 2},
                                  {'foo': 2, 'bar': 3},
                                  {'foo': 1, 'bar': 1},
                                  {'foo': 3, 'bar': 4}]|groupby('foo') -%}
        {{ grouper }}{% for x in list %}: {{ x.foo }}, {{ x.bar }}{% endfor %}|
        {%- endfor %}
        TPL
      ).split("|\n").should eq [
        "1: 1, 2: 1, 1",
        "2: 2, 3",
        "3: 3, 4",
        "",
      ]
    end

    it "tuple_index" do
      render(<<-'TPL'
        {%- for grouper, list in [('a', 1), ('a', 2), ('b', 1)]|groupby(0) -%}
        {{ grouper }}{% for x in list %}:{{ x.1 }}{% endfor %}|
        {%- endfor %}
        TPL
      ).should eq "a:1:2|\nb:1|\n"
    end

    it "multidot" do
      articles = [
        Article.new("aha", 1, 1, 1970),
        Article.new("interesting", 2, 1, 1970),
        Article.new("really?", 3, 1, 1970),
        Article.new("totally not", 1, 1, 1971),
      ]
      render(<<-'TPL',
        {%- for year, list in articles|groupby('date.year') -%}
        {{ year }}{% for x in list %}[{{ x.title }}]{% endfor %}|
        {%- endfor %}
        TPL
        {articles: articles}).split("|\n").should eq [
        "1970[aha][interesting][really?]",
        "1971[totally not]",
        "",
      ]
    end
  end

  it "replace" do
    evaluate_expression(%(string|replace("o", 42)), {string: "<foo>"}).should eq "<f4242>"
    evaluate_expression(%(string|replace("o", 42)), {string: "<foo>"}, autoescape: true).should eq "&lt;f4242&gt;"
    evaluate_expression(%(string|replace("<", 42)), {string: "<foo>"}, autoescape: true).should eq "42foo&gt;"
    evaluate_expression(%(string|replace("o", ">x<")), {string: Crinja::SafeString.new("foo")}, autoescape: true).should eq "f&gt;x&lt;&gt;x&lt;"
  end

  it "forceescape" do
    evaluate_expression(%(x|forceescape), {x: Crinja::SafeString.new("<div />")}).should eq "&lt;div /&gt;"
  end

  it "safe" do
    evaluate_expression(%("<div>foo</div>"|safe), autoescape: true).should eq "<div>foo</div>"
    evaluate_expression(%("<div>foo</div>"), autoescape: true).should eq "&lt;div&gt;foo&lt;/div&gt;"
  end

  it "urlencode" do
    evaluate_expression(%("Hello, world!"|urlencode), autoescape: true).should eq "Hello%2C%20world%21"

    evaluate_expression(%(o|urlencode), {o: "Hello, world\u203d"}, autoescape: true).should eq "Hello%2C%20world%E2%80%BD"
    evaluate_expression(%(o|urlencode), {o: {0 => 1}}, autoescape: true).should eq "0=1"
    evaluate_expression(%(o|urlencode), {o: [{"f", 1}]}, autoescape: true).should eq "f=1"
    evaluate_expression(%(o|urlencode), {o: [{"f", 1}, {"z", 2}]}, autoescape: true).should eq "f=1&amp;z=2"
    evaluate_expression(%(o|urlencode), {o: [{"\u203d", 1}]}, autoescape: true).should eq "%E2%80%BD=1"
    evaluate_expression(%(o|urlencode), {o: {"\u203d": 1}}, autoescape: true).should eq "%E2%80%BD=1"
  end

  describe "map" do
    it "simple_map" do
      evaluate_expression(%(["1", "2", "3"]|map("int")|sum)).should eq "6"
    end

    it "attribute_map" do
      users = [
        User.new("john"),
        User.new("jane"),
        User.new("mike"),
      ]
      evaluate_expression(%(users|map(attribute="username")|join("|")), {users: users}).should eq "john|jane|mike"
    end

    it "empty_map" do
      evaluate_expression(%(none|map("upper")|list)).should eq "[]"
    end
  end

  describe "select/reject" do
    it "simple_select" do
      evaluate_expression(%([1, 2, 3, 4, 5]|select("odd")|join("|"))).should eq "1|3|5"
    end

    it "bool_select" do
      evaluate_expression(%([none, false, 0, 1, 2, 3, 4, 5]|select|join("|"))).should eq "1|2|3|4|5"
    end

    it "simple_reject" do
      evaluate_expression(%([1, 2, 3, 4, 5]|reject("odd")|join("|"))).should eq "2|4"
    end

    it "bool_reject" do
      evaluate_expression(%([none, false, 0, 1, 2, 3, 4, 5]|reject|join("|"))).should eq "none|false|0"
    end

    it "simple_select_attr" do
      users = [
        User.new("john", true),
        User.new("jane", true),
        User.new("mike", false),
      ]
      evaluate_expression(%(users|selectattr("is_active")|map(attribute="username")|join("|")), {users: users}).should eq "john|jane"
    end

    it "simple_reject_attr" do
      users = [
        User.new("john", true),
        User.new("jane", true),
        User.new("mike", false),
      ]
      evaluate_expression(%(users|rejectattr("is_active")|map(attribute="username")|join("|")), {users: users}).should eq "mike"
    end

    it "func_select_attr" do
      users = [
        IdUser.new(1, "john"),
        IdUser.new(2, "jane"),
        IdUser.new(3, "mike"),
      ]
      evaluate_expression(%(users|selectattr("id", "odd")|map(attribute="name")|join("|")),
        {users: users}).should eq "john|mike"
    end

    it "func_reject_attr" do
      users = [
        IdUser.new(1, "john"),
        IdUser.new(2, "jane"),
        IdUser.new(3, "mike"),
      ]
      evaluate_expression(%(users|rejectattr("id", "odd")|map(attribute="name")|join("|")),
        {users: users}).should eq "jane"
    end
  end

  describe "json_dump" do
    it "json_dump" do
      # original jinja2
      # evaluate_expression(%(x|tojson), {x: {"foo" => "bar"}}, autoescape: true).should eq "{&#34;foo&#34;: &#34;bar&#34;}"
      evaluate_expression(%(x|tojson), {x: {"foo" => "bar"}}, autoescape: true).should eq "{\n&quot;foo&quot;: &quot;bar&quot;\n}"
      # evaluate_expression(%(x|tojson), {x: %("bar')}, autoescape: true).should eq "&#34;&#34;bar\u0027&#34;"
      evaluate_expression(%(x|tojson), {x: %("bar')}, autoescape: true).should eq "&quot;\\&quot;bar&#39;&quot;"
    end

    pending "policies" do
      env = Crinja.new
      env.config.autoescape = true
      env.policies["json.dumps_function"] = Crinja.function do
        arguments.kwargs.should eq({"foo", "bar"})
        42
      end
      env.policies["json.dumps_kwargs"] = Crinja.value({"foo" => "bar"})
      env.evaluate(%(x|tojson), {x: 23}).should eq "42"
    end
  end

  it "attr" do
    evaluate_expression(%(data | attr("foo")), {data: {"foo" => "bar"}}).should eq "bar"
    evaluate_expression(%(arr | attr(0)), {arr: ["bar"]}).should eq ""
  end

  describe "list" do
    it "retuns array" do
      evaluate_expression(%([1, 2] | list)).should eq "[1, 2]"
    end
    it "splits string" do
      evaluate_expression(%("abc" | list)).should eq %(['a', 'b', 'c'])
    end
    it "fails for number" do
      expect_raises(Crinja::TypeError) do
        evaluate_expression(%(1 | list))
      end
    end
  end

  it "trim" do
    evaluate_expression(%("  foo. \n"|trim)).should eq "foo."
  end

  describe "wordwrap" do
    it do
      evaluate_expression(%(s|wordwrap), {s: "a" * 79}).should eq "a" * 79
      evaluate_expression(%(s|wordwrap), {s: "a" * 80}).split('\n').should eq ["a" * 79, "a"]
      evaluate_expression(%(s|wordwrap(10)), {s: "foo " * 3}).split('\n').should eq ["foo foo fo", "o "]
    end

    pending do
      evaluate_expression(%(s|wordwrap), {s: "foo " * 20}).split('\n').should eq ["foo " * 19, "foo"]
      evaluate_expression(%(s|wordwrap(10, false)), {s: "foo " * 3}).split('\n').should eq ["foo foo", "foo "]
    end
  end
end
