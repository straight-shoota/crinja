require "../spec_helper"
# tests based on https://github.com/pallets/jinja/blob/master/tests/test_core_tags.py

describe Crinja::Tag::For do
  it "renders for loop with variables" do
    render(%({% for a in abc %}{{ loop.index }}: {{ a }}{% if loop.last %}.{% endif %}{% endfor %}), {"abc" => ["a", "b", "c"]}).should eq("1: a2: b3: c.")
  end

  it "renders for loop" do
    render(%({% for a in ['a', 'b', 'c'] %}{{ loop.index }}: {{ a }}{% if not loop.last %}, {% endif %}{% endfor %})).should eq("1: a, 2: b, 3: c")
  end

  it "renders simple" do
    render(%({% for i in numbers %}{{ i }}{% endfor %}), {"numbers" => [1, 2, 3, 4, 5]}).should eq("12345")
  end

  it "renders else" do
    render(%({% for item in seq %}XXX{% else %}...{% endfor %})).should eq("...")
  end

  it "renders else with correct scoping" do
    render(%({% for item in seq %}XXX{% else %}{{ item }}{% endfor %}), {"item" => "42"}).should eq("42")
  end

  it "renders empty blocks" do
    render(%(<{% for item in seq %}{% else %}{% endfor %}>)).should eq("<>")
  end

  it "renders context vars" do
    bindings = {"seq" => [42, 24]}
    tpl = <<-'TPL'
          {% for item in seq -%}
          {{ loop.index }}|{{ loop.index0 }}|{{ loop.revindex }}|{{
                loop.revindex0 }}|{{ loop.first }}|{{ loop.last }}|{{
               loop.length }}###{% endfor %}
          TPL

    render(tpl, bindings).split("###").map(&.split("|")).should eq([
      ["1", "0", "2", "1", "true", "false", "2"],
      ["2", "1", "1", "0", "false", "true", "2"],
      [""],
    ])
  end

  it "renders cycle" do
    render(%({% for item in seq %}{{
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(*through) }}{% endfor %}), {"seq" => (0..3), "through" => ["<1>", "<2>"]}, autoescape = false).should eq("<1><2>" * 4)
  end

  it "renders with correct scoping" do
    render(%({% for item in seq %}{% endfor %}{{ item }}), {"seq" => (0..1)}).should eq("")
  end

  pending "https://github.com/crystal-lang/crystal/issues/5694" do
    it "varlen" do
      iter = (0..4).each
      render(%({% for item in iter %}{{ item }}{% endfor %}), {"iter" => iter}).should eq("01234")
    end

    it "iterator issue" do
      index = 0
      Crinja::Tag::For::ForLoop.new(Crinja::Value.new((0..4).each)).each do |value|
        value.should eq index
        index += 1
      end
      index.should eq 5
    end
  end

  it "noniter" do
    expect_raises(Crinja::TypeError) do
      render(%({% for item in none %}...{% endfor %}))
    end
  end

  it "recursive" do
    render(<<-'TPL',
      {% for item in seq recursive -%}
      [{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
      {%- endfor %}
      TPL
      {"seq" => [
        {"a" => 1, "b" => [{"a" => 1}, {"a" => 2}]},
        {"a" => 2, "b" => [{"a" => 1}, {"a" => 2}]},
        {"a" => 3, "b" => [{"a" => "a"}]},
      ]}, trim_blocks: true).should eq("[1<[1][2]>][2<[1][2]>][3<[a]>]")
  end

  it "recursive_depth0" do
    %({% for item in seq recursive -%}
    [{{ loop.depth0 }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
    {%- endfor %})

    render(<<-'TPL',
      {% for item in seq recursive -%}
      [{{ loop.depth0 }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
      {%- endfor %}
      TPL
      {"seq" => [
        {"a" => 1, "b" => [{"a" => 1}, {"a" => 2}]},
        {"a" => 2, "b" => [{"a" => 1}, {"a" => 2}]},
        {"a" => 3, "b" => [{"a" => 'a'}]},
      ]}, trim_blocks: true).should eq("[0:1<[1:1][1:2]>][0:2<[1:1][1:2]>][0:3<[1:a]>]")
  end

  it "recursive_depth" do
    %({% for item in seq recursive -%}
      [{{ loop.depth }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %})
    render(<<-'TPL',
      {% for item in seq recursive -%}
      [{{ loop.depth }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
      {%- endfor %}
      TPL
      {"seq" => [
        {"a" => 1, "b" => [{"a" => 1}, {"a" => 2}]},
        {"a" => 2, "b" => [{"a" => 1}, {"a" => 2}]},
        {"a" => 3, "b" => [{"a" => "a"}]},
      ]}, trim_blocks: true).should eq("[1:1<[2:1][2:2]>][1:2<[2:1][2:2]>][1:3<[2:a]>]")
  end

  it "looploop" do
    render(<<-'TPL',
      {% for row in table -%}
      {%- set rowloop = loop -%}
      {%- for cell in row -%}
      [{{ rowloop.index }}|{{ loop.index }}]
      {%- endfor %}
      {%- endfor %}
      TPL
      {"table" => ["ab", "cd"]}, trim_blocks: true, lstrip_blocks: true).should eq "[1|1][1|2][2|1][2|2]"
  end

  it "loop_errors" do
    expect_raises(Crinja::UndefinedError) do
      render(%({% for item in [1] if loop.index == 0 %}...{% endfor %}))
    end
    render(%({% for item in [] %}...{% else %}{{ loop }}{% endfor %})).should eq ""
  end

  it "loop_filter" do
    render(%({% for item in range(10) if item is even %}[{{ item }}]{% endfor %})).should eq "[0][2][4][6][8]"
    render(%({%- for item in range(10) if item is even %}[{{ loop.index }}:{{ item }}]{% endfor %})).should eq "[1:0][2:2][3:4][4:6][5:8]"
  end

  it "loop_unassignable" do
    expect_raises(Crinja::TemplateSyntaxError) do
      render %({% for loop in seq %}...{% endfor %})
    end
  end

  it "scoped_special_var" do
    render(%({% for s in seq %}[{{ loop.first }}{% for c in s %}|{{ loop.first }}{% endfor %}]{% endfor %}), {
      "seq" => ["ab", "cd"],
    }).should eq "[true|true|false][false|true|false]"
  end

  it "scoped_loop_var" do
    render(%({% for x in seq %}{{ loop.first }}{% for y in seq %}{% endfor %}{% endfor %}), {"seq" => "ab"}).should eq "truefalse"
    render(%({% for x in seq %}{% for y in seq %}{{ loop.first }}{% endfor %}{% endfor %}), {"seq" => "ab"}).should eq "truefalsetruefalse"
  end

  it "recursive_empty_loop_iter" do
    render(%({%- for item in foo recursive -%}{%- endfor -%}), {"foo" => [] of String}).should eq ""
  end

  pending "call_in_loop" do
    render(<<-'TPL').should eq "[1][2][3]"
        {%- macro do_something() -%}
            [{{ caller() }}]
        {%- endmacro %}
        {%- for i in [1, 2, 3] %}
            {%- call do_something() -%}
                {{ i }}
            {%- endcall %}
        {%- endfor -%}
        TPL
  end

  it "scoping_bug" do
    render(<<-'TPL', {"foo" => [1]}).should eq "...1......2..."
        {%- for item in foo %}...{{ item }}...{% endfor -%}
        {%- macro item(a) %}...{{ a }}...{% endmacro -%}
        {{- item(2) -}}
        TPL
  end

  it "unpacking" do
    render(%({% for a, b, c in [[1, 2, 3]] %}{{ a }}|{{ b }}|{{ c }}{% endfor %})).should eq "1|2|3"
  end

  it "intended_scoping_with_set" do
    bindings = {"x" => 0, "seq" => [1, 2, 3]}
    render(%({% for item in seq %}{{ x }}{% set x = item %}{{ x }}{% endfor %}), bindings).should eq "010203"
    render(%({% set x = 9 %}{% for item in seq %}{{ x }}{% set x = item %}{{ x }}{% endfor %}), bindings).should eq "919293"
  end
end
