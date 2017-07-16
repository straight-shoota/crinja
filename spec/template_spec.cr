require "./spec_helper"

describe Crinja::Template do
  it "#dynamic?" do
    Crinja::Template.new("{{ foo }}").dynamic?.should be_true
    Crinja::Template.new("Foo{{ foo }}").dynamic?.should be_true
    Crinja::Template.new(%(Foo{% set foo="foo" %})).dynamic?.should be_true
    Crinja::Template.new(%({% set foo="foo" %})).dynamic?.should be_true
    Crinja::Template.new("").dynamic?.should be_false
    Crinja::Template.new("Foo").dynamic?.should be_false
  end
end
