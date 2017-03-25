require "../spec_helper.cr"

describe Crinja::Tag::Set do
  it "normal" do
    env = Crinja::Environment.new
    env.from_string("{% set foo = 1 %}{{ foo }}").render(env).should eq("1")
    env.resolve("foo").should eq 1
  end

  it "block" do
    env = Crinja::Environment.new
    template = env.from_string("{% set foo %}42{% endset %}{{ foo }}")
    ctx = env.context
    template.render(ctx).should eq "42"
    ctx["foo"].should eq "42"
  end

  it "block_escaping" do
    render("{% set foo %}<em>{{ test }}</em>{% endset %}foo: {{ foo }}", {"test" => "<unsafe>"}).should eq("foo: <em>&lt;unsafe&gt;</em>")
  end
end
