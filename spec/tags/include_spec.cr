require "../spec_helper"

# tests based on https://github.com/pallets/jinja/blob/master/tests/test_core_tags.py

def test_loader
  loader = Crinja::Loader::HashLoader.new({
    "header" => "[{{ foo }}|{{ 23 }}]",
  })
end

describe Crinja::Tag::Include do
  it "context_include" do
    render(%({% include "header" %}), {"foo" => 42}, loader: test_loader).should eq "[42|23]"
  end
  it "incude with context" do
    loader = Crinja::Loader::HashLoader.new({
      "header" => "[{{ foo }}|{{ 23 }}]",
    })
    render(%({% include "header" with context %}), {"foo" => 42}, loader: test_loader).should eq "[42|23]"
  end
  it "includes without context" do
    loader = Crinja::Loader::HashLoader.new({
      "header" => "[{{ foo }}|{{ 23 }}]",
    })
    render(%({% include "header" without context %}), {"foo" => 42}, loader: test_loader).should eq "[|23]"
  end

  it "includes choice" do
    render(%({% include ["missing", "header"] %}), {"foo" => 42}, loader: test_loader).should eq "[42|23]"
  end

  it "include ignore missing" do
    render(%({% include ["missing", "missing2"] ignore missing %}), {"foo" => 42}, loader: test_loader).should eq ""
  end

  it "include missing raises" do
    expect_raises(Crinja::TemplateNotFoundError, %(templates ["missing", "missing2"] could not be found)) do
      render(%({% include ["missing", "missing2"] %}))
    end
  end

  it "include with variable" do
    render(%({% include x %}), {"foo" => 42, "x" => ["missing", "header"]}, loader: test_loader).should eq "[42|23]"
    render(%({% include [x, "header"] %}), {"foo" => 42, "x" => "missing"}, loader: test_loader).should eq "[42|23]"
    render(%({% include x %}), {"foo" => 42, "x" => "header"}, loader: test_loader).should eq "[42|23]"
  end

  it "include ignore missing with context" do
    render(%({% include "missing" ignore missing with context %}), loader: test_loader).should eq ""
  end

  it "include ignore missing without context" do
    render(%({% include "missing" ignore missing without context %}), loader: test_loader).should eq ""
  end

  it "context include with override" do
    env = Crinja.new
    env.loader = Crinja::Loader::HashLoader.new({
      "main" => "{% for item in [1, 2, 3] %}{% include 'item' %}{% endfor %}",
      "item" => "{{ item }}",
    })
    env.get_template("main").render.should eq "123"
  end

  it "unoptimized_scopes" do
    render(<<-'TPL',
            {% macro outer(o) %}
            {% macro inner() %}
            {% include "o_printer" %}
            {% endmacro %}
            {{ inner() }}
            {% endmacro %}
            {{ outer("FOO") }}
            TPL


      loader: Crinja::Loader::HashLoader.new({"o_printer" => "({{ o }})"})).strip.should eq "(FOO)"
  end

  it "import_from_with_context" do
    loader = Crinja::Loader::HashLoader.new({
      "a" => "{% macro x() %}{{ foobar }}{% endmacro %}",
    })
    render(%({% set foobar = 42 %}{% from "a" import x with context %}{{ x() }}), loader: loader).should eq "42"
  end
end
