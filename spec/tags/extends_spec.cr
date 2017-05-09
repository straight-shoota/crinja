require "../spec_helper"
# test based on https://github.com/pallets/jinja/blob/master/tests/test_inheritance.py

INHERITANCE_TEST_LOADER = Crinja::Loader::HashLoader.new({
  "layout" => <<-'TPL'
|{% block block1 %}block 1 from layout{% endblock %}
|{% block block2 %}block 2 from layout{% endblock %}
|{% block block3 %}
{% block block4 %}nested block 4 from layout{% endblock %}
{% endblock %}|
TPL,

  "level1" => <<-'TPL'
{% extends "layout" %}
{% block block1 %}block 1 from level1{% endblock %}
TPL,

  "level2" => <<-'TPL'
{% extends "level1" %}
{% block block2 %}{% block block5 %}nested block 5 from level2{%
endblock %}{% endblock %}
TPL,

  "level3" => <<-'TPL'
{% extends "level2" %}
{% block block5 %}block 5 from level3{% endblock %}
{% block block4 %}block 4 from level3{% endblock %}
TPL,

  "level4" => <<-'TPL'
{% extends "level3" %}
{% block block3 %}block 3 from level4{% endblock %}
TPL,

  "working" => <<-'TPL'
{% extends "layout" %}
{% block block1 %}
{% if false %}
{% block block2 %}
this should workd
{% endblock %}
{% endif %}
{% endblock %}
TPL,

  "doublee" => <<-'TPL'
{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
{% if false %}
{% block block2 %}
this should workd
{% endblock %}
{% endif %}
{% endblock %}
TPL,
})

describe Crinja::Tag::Extends do
  it "simple" do
    render("{% extends 'parent' %}", loader: Crinja::Loader::HashLoader.new({"parent" => "foo"})).should eq "foo"
  end

  it "resolves block" do
    loader = Crinja::Loader::HashLoader.new({"parent" => "Hello {% block name %}World{% endblock %}"})
    render("{% extends 'parent' %}Ignored{% block name %}Block{% endblock %}", loader: loader).should eq "Hello Block"
  end

  it "layout" do
    render_load("layout", loader: INHERITANCE_TEST_LOADER, trim_blocks: true).should eq "|block 1 from layout|block 2 from layout|nested block 4 from layout|"
  end

  it "level1" do
    render_load("level1", loader: INHERITANCE_TEST_LOADER, trim_blocks: true).should eq "|block 1 from level1|block 2 from layout|nested block 4 from layout|"
  end

  it "level2" do
    render_load("level2", loader: INHERITANCE_TEST_LOADER, trim_blocks: true).should eq "|block 1 from level1|nested block 5 from level2|nested block 4 from layout|"
  end

  it "level3" do
    render_load("level3", loader: INHERITANCE_TEST_LOADER, trim_blocks: true).should eq "|block 1 from level1|block 5 from level3|block 4 from level3|"
  end

  it "level4" do
    render_load("level4", loader: INHERITANCE_TEST_LOADER, trim_blocks: true).should eq "|block 1 from level1|block 5 from level3|block 3 from level4|"
  end

  it "super1" do
    loader = Crinja::Loader::HashLoader.new({
      "a" => "{% block intro %}INTRO{% endblock %}|" \
             "BEFORE|{% block data %}INNER{% endblock %}|AFTER",
      "c" => "{% extends 'a' %}{% block intro %}--{{ " \
             "super() }}--{% endblock %}\n{% block data " \
             "%}[{{ super() }}]{% endblock %}",
    })
    render_load("c", loader: loader).should eq "--INTRO--|BEFORE|[INNER]|AFTER"
  end

  it "super2" do
    loader = Crinja::Loader::HashLoader.new({
      "a" => "{% block intro %}INTRO{% endblock %}|" \
             "BEFORE|{% block data %}INNER{% endblock %}|AFTER",
      "b" => "{% extends 'a' %}{% block data %}({{ " \
             "super() }}){% endblock %}",
      "c" => "{% extends 'b' %}{% block intro %}--{{ " \
             "super() }}--{% endblock %}\n{% block data " \
             "%}[{{ super() }}]{% endblock %}",
    })
    render_load("c", loader: loader).should eq "--INTRO--|BEFORE|[(INNER)]|AFTER"
  end

  it "working" do
    tmpl = render_load("working", loader: INHERITANCE_TEST_LOADER)
  end

  # self.block() requires extension to the current output node model
  pending "reuse_blocks" do
    render("{{ self.foo() }}|{% block foo %}42" \
           "{% endblock %}|{{ self.foo() }}").should eq "42|42|42"
  end

  pending "preserve_blocks" do
    loader = Crinja::Loader::HashLoader.new({
      "a" => "{% if false %}{% block x %}A{% endblock %}" \
             "{% endif %}{{ self.x() }}",
      "b" => "{% extends 'a' %}{% block x %}B{{ super() }}{% endblock %}",
    })
    render_load("b", loader: loader).should eq "BA"
  end

  it "dynamic_inheritance" do
    loader = Crinja::Loader::HashLoader.new({
      "master1" => "MASTER1{% block x %}{% endblock %}",
      "master2" => "MASTER2{% block x %}{% endblock %}",
      "child"   => "{% extends master %}{% block x %}CHILD{% endblock %}",
    })
    env = Crinja::Environment.new
    env.loader = loader
    template = env.get_template("child")
    [1, 2].each do |m|
      template.render({"master" => "master%d" % m}).should eq "MASTER%dCHILD" % m
    end
  end

  it "multi_inheritance" do
    loader = Crinja::Loader::HashLoader.new({
      "master1" => "MASTER1{% block x %}{% endblock %}",
      "master2" => "MASTER2{% block x %}{% endblock %}",
      "child"   => "{% if master %}{% extends master %}{% else %}{% extends" \
                 "'master1' %}{% endif %}{% block x %}CHILD{% endblock %}",
    })
    env = Crinja::Environment.new
    env.loader = loader
    template = env.get_template("child")
    template.render({"master" => "master2"}).should eq "MASTER2CHILD"
    template.render({"master" => "master1"}).should eq "MASTER1CHILD"
    template.render.should eq "MASTER1CHILD"
  end

  it "scoped_block" do
    loader = Crinja::Loader::HashLoader.new({
      "master.html" => "{% for item in seq %}[{% block item scoped %}" \
                       "{% endblock %}]{% endfor %}",
    })
    render(%({% extends "master.html" %}{% block item %}{{ item }}{% endblock %}), {
      "seq" => (0..4).to_a,
    }, loader: loader).should eq "[0][1][2][3][4]"
  end

  it "super_in_scoped_block" do
    loader = Crinja::Loader::HashLoader.new({
      "master.html" => "{% for item in seq %}[{% block item scoped %}" \
                       "{{ item }}{% endblock %}]{% endfor %}",
    })
    render(%({% extends "master.html" %}{% block item %}{{ super() }}|{{ item * 2 }}{% endblock %}), {
      "seq" => (0..4).to_a,
    }, loader: loader).should eq "[0|0][1|2][2|4][3|6][4|8]"
  end

  it "scoped_block_after_inheritance" do
    loader = Crinja::Loader::HashLoader.new({
      "layout.html" => <<-'TPL'
{% block useless %}*{% endblock %}
TPL,
      "index.html" => <<-'TPL'
{%- extends 'layout.html' %}
{% from 'helpers.html' import foo with context %}
{% block useless %}
    {% for x in [1, 2, 3] %}
        {% block testing scoped %}
            {{ foo(x) }}
        {% endblock %}
    {% endfor %}
{% endblock %}
TPL,
      "helpers.html" => <<-'TPL'
{% macro foo(x) %}{{ the_foo + x }}{% endmacro %}
TPL,
    })
    render_load("index.html", {"the_foo" => 42}, loader: loader).split.should eq ["43", "44", "45"]
  end
end
