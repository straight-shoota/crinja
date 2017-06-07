require "../spec_helper.cr"

describe "function joiner" do
  it "joins" do
    render(%({% set pipe = joiner('|') %}{{ pipe() }}-{{ pipe() }}-{{ pipe() }})).should eq "-|-|"
  end
end
