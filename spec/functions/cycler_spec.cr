require "../spec_helper.cr"

describe "function cycler" do
  it "cycles" do
    render(%({% set class = cycler(0, '1') %}{% for i in range(5) %}{{ class.next }}{% endfor %})).should eq "01010"
  end
  it "cycles" do
    render(%({% set class = cycler(0, '1') %}{% for i in range(5) %}{{ class.next() }}{% endfor %})).should eq "01010"
  end
end
