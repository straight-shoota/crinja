require "../spec_helper.cr"

describe Crinja::Tag::Filter do
  it "simple filter" do
    env = Crinja.new
    env.from_string("{% filter upper %}Hello {{ name }}!{% endfilter %}").render({"name" => "John"}).should eq("HELLO JOHN!")
  end

  it "block" do
    render(%({% filter lower|escape %}<HEHE>{% endfilter %})).should eq "&lt;hehe&gt;"
  end
end
