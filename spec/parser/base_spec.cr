require "../spec_helper"

describe Crinja::Parser::TemplateParser do
  it "parses a simple template string" do
    parser = Crinja::Parser::TemplateParser.new(Crinja::Environment.new, "Hallo Welt")
    tree = parser.parse

    tree.should be_a(Crinja::AST::NodeList)
    tree.children.size.should eq 1
    tree.children.first.should be_a Crinja::AST::FixedString
  end

  it "parses dict reference" do
    render(%({% for a in [{ "foo": "bar" }] %}{{ a.foo }}{% endfor %})).should eq("bar")
  end
end
