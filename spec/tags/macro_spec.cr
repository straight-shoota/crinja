require "../spec_helper"
# test based on https://github.com/pallets/jinja/blob/d905cf0b6c6121d900ea384f72970b862c879bc7/tests/test_core_tags.py

describe Crinja::Tag::Macro do
  it "simple" do
    render(<<-'TPL'
      {% macro say_hello(name) %}Hello {{ name }}!{% endmacro -%}
      {{ say_hello('Peter') }}
      TPL).should eq "Hello Peter!"
  end

  it "scoping" do
    render(<<-'TPL'
      {% macro level1(data1) -%}
      {% macro level2(data2) %}{{ data1 }}|{{ data2 }}{% endmacro -%}
      {{ level2('bar') }}{% endmacro -%}
      {{ level1('foo') }}
      TPL).should eq "foo|bar"
  end

  it "arguments" do
    render(<<-'TPL'
      {% macro m(a, b, c='c', d='d') %}{{ a }}|{{ b }}|{{ c }}|{{ d }}{% endmacro -%}
      {{ m() }}|{{ m('a') }}|{{ m('a', 'b') }}|{{ m(1, 2, 3) }}
      TPL).should eq "||c|d|a||c|d|a|b|c|d|1|2|3|d"
  end

  it "arguments_defaults_nonsense" do
    expect_raises(Crinja::TemplateSyntaxError) do
      render(%({% macro m(a, b=1, c) %}a={{ a }}, b={{ b }}, c={{ c }}{% endmacro %}))
    end
  end

  pending "caller_defaults_nonsense" do
    expect_raises(Crinja::TemplateSyntaxError) do
      render(%({% macro a() %}{{ caller() }}{% endmacro %}{% call(x, y=1, z) a() %}{% endcall %}))
    end
  end

  it "varargs" do
    render(%({% macro test() %}{{ varargs|join('|') }}{% endmacro %}{{ test(1, 2, 3) }})).should eq "1|2|3"
  end

  pending "simple_call" do
    render(%({% macro test() %}[[{{ caller() }}]]{% endmacro %}{% call test() %}data{% endcall %})).should eq "[[data]]"
  end

  pending "complex_call" do
    render(%({% macro test() %}[[{{ caller('data') }}]]{% endmacro %}{% call(data) test() %}{{ data }}{% endcall %})).should eq "[[data]]"
  end

  pending "caller_undefined" do
    render(%({% set caller = 42 %}{% macro test() %}{{ caller is not defined }}{% endmacro %}{{ test() }})).should eq "True"
  end

  pending "include" do
    render(%({% from "include" import test %}{{ test("foo") }}), loader: HashLoader.new({
      "include": "{% macro test(foo) %}[{{ foo }}]{% endmacro %}",
    })).should eq "[foo]"
  end

  pending "macro_api" do
    tmpl = env.from_string(<<-'TPL'
         {% macro foo(a, b) %}{% endmacro %}
         {% macro bar() %}{{ varargs }}{{ kwargs }}{% endmacro %}
         {% macro baz() %}{{ caller() }}{% endmacro %}
         TPL)
    tmpl.module["foo"].arguments.should eq ["a", "b"]
    tmpl.module["foo"].name.should eq "foo"
    tmpl.module["foo"].caller.should_not be_true
    tmpl.module["foo"].catch_kwargs.should_not be_true
    tmpl.module["foo"].catch_varargs.should_not be_true
    tmpl.module["bar"].arguments.should eq [] of String
    tmpl.module["bar"].caller.should_not be_true
    tmpl.module["bar"].catch_kwargs.should be_true
    tmpl.module["bar"].catch_varargs.should be_true
    tmpl.module["baz"].caller.should be_true
  end

  it "callself" do
    render(<<-'TPL'
      {% macro foo(x) %}{{ x }}{% if x > 1 %}|{{ foo(x - 1) }}{% endif %}{% endmacro %}{{ foo(5) }}
      TPL).should eq "5|4|3|2|1"
  end

  pending "macro_defaults_self_ref" do
    # tmpl = env.from_string('''
    #      {%- set x = 42 %}
    #      {%- macro m(a, b=x, x=23) %}{{ a }}|{{ b }}|{{ x }}{% endmacro -%}

    # TPL
    #  assert tmpl.module.m(1) == '1||23'
    #  assert tmpl.module.m(1, 2) == '1|2|23'
    #  assert tmpl.module.m(1, 2, 3) == '1|2|3'
    #  assert tmpl.module.m(1, x=7) == '1|7|7'
  end
end
