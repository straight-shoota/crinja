require "./spec_helper"
require "../../src/json"

describe JSON::Any do
  it "can be used as Crinja::Value" do
    env = Crinja.new

    any = JSON::Any.new({
      "bar" => JSON::Any.new [JSON::Any.new("BAR!")],
    })
    env.from_string("{{ foo.bar[0] }}: {{ baz }}").render({"foo" => any, "baz" => JSON::Any.new(1_i64)}).should eq "BAR!: 1"
  end
end
