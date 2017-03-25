require "../spec_helper"

describe "whitespace" do
  it "trims whitespace after tag" do
    template = parse(%(<div>\n    {% if true -%}\n        yay\n    {% endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("        yay\n    ")
  end

  it "trims blocks before tag" do
    template = parse(%(<div>\n    {% if true %}\n        yay\n    {%- endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("\n        yay")
  end

  it "trims blocks before and after tag" do
    template = parse(%(<div>\n    {% if true -%}\n        yay\n    {%- endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("        yay")
  end
end
