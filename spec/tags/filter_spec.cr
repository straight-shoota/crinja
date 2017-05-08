require "../spec_helper.cr"

describe Crinja::Tag::Filter do
  it "simple filter" do
    env = Crinja::Environment.new
    env.from_string("{% filter upper %}Hello {{ name }}!{% endfilter %}").render({"name" => "John"}).should eq("HELLO JOHN!")
  end
end
