require "./spec_helper"

describe Crinja::Parser::TemplateParser do
  it "parses a simple template string" do
    template = Crinja::Template.new("Hallo Welt")
    parser = Crinja::Parser::TemplateParser.new(template, Crinja::Node::Root.new(template))
    tree = parser.build.root

    tree.should be_a(Crinja::Node::Root)
    tree.children.size.should eq 1
    tree.children.first.should be_a Crinja::Node::Text
    tree.children.first.token.value.should eq "Hallo Welt"
  end

  it "parses dict reference" do
    render(%({% for a in [{ "foo": "bar" }] %}{{ a.foo }}{% endfor %})).should eq("bar")
  end
end
