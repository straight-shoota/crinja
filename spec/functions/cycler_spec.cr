require "../spec_helper.cr"

describe "function cycler" do
  it "cycles" do
    render(%({% set class = cycler(0, '1') %}{% for i in range(5) %}{{ class.next }}{% endfor %})).should eq "01010"
  end
  it "cycles" do
    render(%({% set class = cycler(0, '1') %}{% for i in range(5) %}{{ class.next() }}{% endfor %})).should eq "01010"
  end
  it "cycles with current and reset" do
    render(%({% set c = cycler('a', 'b') %}\
      {{ c.current }}|{{ c.next }}|{{ c.current }}|{{ c.reset() }}|\
      {{ c.current }}|{{ c.next }}|{{ c.rewind }}|{{ c.next }})).should eq "|a|a|||a||a"
  end
end
