require "../spec_helper.cr"
# tests based on https://github.com/pallets/jinja/blob/master/tests/test_core_tags.py

describe Crinja::Tag::If do
  it "simple" do
    render(%({% if true %}...{% endif %})).should eq "..."
  end

  it "elif" do
    render(%({% if false %}FFF{% elif true
            %}...{% else %}XXX{% endif %})).should eq "..."
  end

  it "else" do
    render(%({% if false %}XXX{% else %}...{% endif %})).should eq "..."
  end

  it "empty" do
    render(%([{% if true %}{% else %}{% endif %}])).should eq "[]"
  end

  it "complete" do
    render(%({% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}), {"a" => 0, "b" => false, "c" => 42, "d" => 42.0}).should eq "C"
  end

  it "no_scope" do
    render(%({% if a %}{% set foo = 1 %}{% endif %}{{ foo }}), {"a" => true}).should eq "1"
    render(%({% if true %}{% set foo = 1 %}{% endif %}{{ foo }})).should eq "1"
  end
end
