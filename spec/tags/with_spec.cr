require "../spec_helper.cr"

describe "with" do
  it "local scope" do
    render(%({% with %}{% set foo = 42 %}{{ foo }}{% endwith %}|{{ foo }})).should eq "42|"
  end
  it "set variables in tag start" do
    render(%({% with foo = 42 %}{{ foo }}{% endwith %}|{{ foo }})).should eq "42|"
  end
  it "references external scope in opening assignments" do
    render(%({% with a = {}, b=a.foo %}{{ b }}{% endwith %}), {a: {"foo" => "bar"}}).should eq "bar"
  end
  it "references internal scope in set tags" do
    render(%({% with a = {"foo": "baz"} %}{% set b = a.foo %}{{ b }}{% endwith %}), {a: {"foo" => "bar"}}).should eq "baz"
  end
end
