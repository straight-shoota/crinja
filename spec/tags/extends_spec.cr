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
end
