require "../spec_helper"

describe "whitespace" do
  it "trims whitespace after tag" do
    template = parse(%(<div>\n    {% if true -%}\n        yay\n    {% endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("        yay\n    ")
  end

  it "trims before tag" do
    template = parse(%(<div>\n    {% if true %}\n        yay\n    {%- endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("\n        yay\n")
  end

  it "trims before tag with lstrip blocks" do
    template = parse(%(<div>\n    {% if true %}\n        yay\n    {%- endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value(false, true).should eq("\n        yay")
  end

  it "trims before and after tag" do
    template = parse(%(<div>\n    {% if true -%}\n        yay\n    {%- endif %}\n</div>))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("        yay\n")
  end

  it "trims empty text left side correctly" do
    template = parse(%({% if true %}\n    {%- set foo="bar" -%}\n  {% endif %}))
    template.root.children[0].children[0].as(Crinja::Node::Text).value.should eq("\n")
    template.root.children[0].children[2].as(Crinja::Node::Text).value.should eq("  ")
    template.render.should eq "\n  "
  end

  it "trims empty text right side correctly" do
    template = parse(%({% if true -%}\n    {% set foo="bar" %}\n  {%- endif %}))
    template.root.children[0].children[0].as(Crinja::Node::Text).value.should eq("    ")
    template.root.children[0].children[2].as(Crinja::Node::Text).value.should eq("\n")
    template.render.should eq "    \n"
  end

  it "trims empty text both sides correctly" do
    template = parse(%({% if true -%}\n    {%- set foo="bar" -%}\n  {%- endif %}))
    template.root.children[0].children[0].as(Crinja::Node::Text).value.should eq("")
    template.root.children[0].children[2].as(Crinja::Node::Text).value.should eq("")
    template.render.should eq ""
  end

  it "trims around blocks" do
    template = parse(%(  {%- for item in item_list -%}\n    {{ item }}{% if not loop.last %},{% endif -%}\n  {%- endfor -%}))
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("    ")
    template.root.children[1].children[3].as(Crinja::Node::Text).value.should eq("")
  end

  it "trims around blocks with `trim_blocks`" do
    env = Crinja::Environment.new
    env.config.trim_blocks = true
    string = %(  {%- for item in item_list -%}\n    {{ item }}{% if not loop.last %},{% endif %}\n  {%- endfor -%})
    template = Crinja::Template.new(string)
    template.root.children[1].children[0].as(Crinja::Node::Text).value.should eq("    ")
    template.root.children[1].children[3].as(Crinja::Node::Text).value.should eq("\n")
  end
end
