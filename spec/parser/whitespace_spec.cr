require "../spec_helper"

private def text_value(node, trim_blocks = false, lstrip_blocks = false)
  Crinja::Renderer.trim_text(node.as(Crinja::Parser::FixedString), trim_blocks, lstrip_blocks)
end

describe "whitespace" do
  it "trims whitespace after tag" do
    template = parse(%(<div>\n    {% if true -%}\n        yay\n    {% endif %}\n</div>))
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[0]).should eq("        yay\n    ")
  end

  it "trims before tag" do
    template = parse(%(<div>\n    {% if true %}\n        yay\n    {%- endif %}\n</div>))
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[0]).should eq("\n        yay\n")
  end

  it "trims before tag with lstrip blocks" do
    template = parse(%(<div>\n    {% if true %}\n        yay\n    {%- endif %}\n</div>))
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[0], false, true).should eq("\n        yay")
  end

  it "trims before and after tag" do
    template = parse(%(<div>\n    {% if true -%}\n        yay\n    {%- endif %}\n</div>))
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[0]).should eq("        yay\n")
  end

  it "trims empty text left side correctly" do
    template = parse(%({% if true %}\n    {%- set foo="bar" -%}\n  {% endif %}))
    text_value(template.nodes.children[0].as(Crinja::Parser::TagNode).block.children[0]).should eq("\n")
    text_value(template.nodes.children[0].as(Crinja::Parser::TagNode).block.children[2]).should eq("  ")
    template.render.should eq "\n  "
  end

  it "trims empty text right side correctly" do
    template = parse(%({% if true -%}\n    {% set foo="bar" %}\n  {%- endif %}))
    text_value(template.nodes.children[0].as(Crinja::Parser::TagNode).block.children[0]).should eq("    ")
    text_value(template.nodes.children[0].as(Crinja::Parser::TagNode).block.children[2]).should eq("\n")
    template.render.should eq "    \n"
  end

  it "trims empty text both sides correctly" do
    template = parse(%({% if true -%}\n    {%- set foo="bar" -%}\n  {%- endif %}))
    text_value(template.nodes.children[0].as(Crinja::Parser::TagNode).block.children[0]).should eq("")
    text_value(template.nodes.children[0].as(Crinja::Parser::TagNode).block.children[2]).should eq("")
    template.render.should eq ""
  end

  it "trims around blocks" do
    template = parse(%(  {%- for item in item_list -%}\n    {{ item }}{% if not loop.last %},{% endif -%}\n  {%- endfor -%}))
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[0]).should eq("    ")
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[3]).should eq("")
  end

  it "trims around blocks with `trim_blocks`" do
    env = Crinja::Environment.new
    env.config.trim_blocks = true
    string = %(  {%- for item in item_list -%}\n    {{ item }}{% if not loop.last %},{% endif %}\n  {%- endfor -%})
    template = Crinja::Template.new(string)
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[0]).should eq("    ")
    text_value(template.nodes.children[1].as(Crinja::Parser::TagNode).block.children[3]).should eq("\n")
  end
end
