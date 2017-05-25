require "../spec_helper"

describe "function range" do

  it "negative range" do
    render(%({% for i in range(10, 5, -1) %}{{ i }} {% endfor %})).should eq "10 9 8 7 6"
  end
end
