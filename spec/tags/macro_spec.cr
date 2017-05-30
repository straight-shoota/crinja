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
    expect_raises(Crinja::TemplateSyntaxError | Crinja::ExceptionWrapper, "Expected KW_ASSIGN") do
      render(%({% macro m(a, b=1, c) %}a={{ a }}, b={{ b }}, c={{ c }}{% endmacro %}))
    end
  end

  it "caller_defaults_nonsense" do
    expect_raises(Crinja::TemplateSyntaxError | Crinja::ExceptionWrapper) do
      render(%({% macro a() %}{{ caller() }}{% endmacro %}{% call(x, y=1, z) a() %}{% endcall %}))
    end
  end

  it "varargs" do
    render(%({% macro test() %}{{ varargs|join('|') }}{% endmacro %}{{ test(1, 2, 3) }})).should eq "1|2|3"
  end

  it "simple_call" do
    render(%({% macro test() %}[[{{ caller() }}]]{% endmacro %}{% call test() %}data{% endcall %})).should eq "[[data]]"
  end

  it "complex_call" do
    render(%({% macro test() %}[[{{ caller('data') }}]]{% endmacro %}{% call(data) test() %}{{ data }}{% endcall %})).should eq "[[data]]"
  end

  pending "caller_undefined" do
    render(%({% set caller = 42 %}{% macro test() %}{{ caller is not defined }}{% endmacro %}{{ test() }})).should eq "true"
  end

  it "include" do
    render(%({% from "include" import test %}{{ test("foo") }}), loader: Crinja::Loader::HashLoader.new({
      "include" => "{% macro test(foo) %}[{{ foo }}]{% endmacro %}",
    })).should eq "[foo]"
  end

  it "macro_api" do
    tmpl = Crinja::Environment.new.from_string(<<-'TPL'
         {% macro foo(a, b) %}{% endmacro %}
         {% macro bar() %}{{ varargs }}{{ kwargs }}{% endmacro %}
         {% macro baz() %}{{ caller() }}{% endmacro %}
         TPL)
    tmpl.render
    tmpl.macros["foo"].arguments.should eq ["a", "b"]
    tmpl.macros["foo"].name.should eq "foo"
    tmpl.macros["foo"].caller.should_not be_true
    tmpl.macros["foo"].catch_kwargs.should_not be_true
    tmpl.macros["foo"].catch_varargs.should_not be_true
    tmpl.macros["bar"].arguments.should eq [] of String
    tmpl.macros["bar"].caller.should_not be_true
  end

  # TODO: Inspect macro body for usage of `varargs`, `kwargs` and `caller()` -> Tree Traversal
  # TODO: Create macro functions without calling render
  pending "macro_api_ctd" do
    tmpl = Crinja::Environment.new.from_string(<<-'TPL'
         {% macro foo(a, b) %}{% endmacro %}
         {% macro bar() %}{{ varargs }}{{ kwargs }}{% endmacro %}
         {% macro baz() %}{{ caller() }}{% endmacro %}
         TPL)
    tmpl.macros["bar"].catch_kwargs.should be_true
    tmpl.macros["bar"].catch_varargs.should be_true
    tmpl.macros["baz"].caller.should be_true
  end

  it "callself" do
    render(<<-'TPL'
      {% macro foo(x) %}{{ x }}{% if x > 1 %}|{{ foo(x - 1) }}{% endif %}{% endmacro %}{{ foo(5) }}
      TPL).should eq "5|4|3|2|1"
  end

  # TODO: Ignore context outside macro for execution
  # TODO: Apply argument values as default for others (`b=x`)
  pending "macro_defaults_self_ref" do
    env = Crinja::Environment.new
    tmpl = env.from_string(<<-'TPL'
         {%- set x = 42 %}
         {%- macro m(a, b=x, x=23) %}{{ a }}|{{ b }}|{{ x }}{% endmacro -%}
         TPL)
    tmpl.render
    m = tmpl.macros["m"]
    m.call(m.create_arguments(env, [Crinja::Value.new(1), Crinja::Value.new(2)])).should eq "1|2|23"
    m.call(m.create_arguments(env, [Crinja::Value.new(1), Crinja::Value.new(2), Crinja::Value.new(3)])).should eq "1|2|3"
    m.call(m.create_arguments(env, [Crinja::Value.new(1)])).should eq "1||23"
    m.call(m.create_arguments(env, [Crinja::Value.new(1)], {"x" => Crinja::Value.new(7)})).should eq "1|7|7"
  end
end
