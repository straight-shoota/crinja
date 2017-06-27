require "../spec_helper.cr"

describe "autoescape" do
  it "autescape true" do
    render(%({% autoescape true %}{{ "<script>" }}{% endautoescape %})).should eq "&lt;script&gt;"
  end
  it "autescape false" do
    render(%({% autoescape false %}{{ "<script>" }}{% endautoescape %})).should eq "<script>"
  end
end
