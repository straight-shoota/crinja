require "../spec_helper.cr"

describe Crinja::Tag::Set do
  it "normal" do
    env = Crinja.new
    env.from_string("{% set foo = 1 %}{{ foo }}").render(env).should eq("1")
    env.resolve("foo").should eq Crinja::Value.new(1)
  end

  it "block" do
    env = Crinja.new
    template = env.from_string("{% set foo %}42{% endset %}{{ foo }}")
    ctx = env.context
    template.render(ctx).should eq "42"
    ctx["foo"].should eq Crinja::Value.new("42")
  end

  it "block_escaping" do
    render("{% set foo %}<em>{{ test }}</em>{% endset %}foo: {{ foo }}", {"test" => "<unsafe>"}, autoescape: true).should eq("foo: <em>&lt;unsafe&gt;</em>")
  end

  it "raises error for unclosed tag" do
    expect_raises(Crinja::TemplateSyntaxError, "endset") do
      render(%({% set foo %}{{ foo }}))
    end
  end

  it "set variable shadows global function of the same name" do
    env = Crinja.new
    env.functions["foo"] = Crinja.function do
      Crinja::Value.new("function_result")
    end

    template = env.from_string(%({% set foo = "bar" %}{{ foo }}))
    result = template.render(env)
    result.should eq "bar"
  end
end
