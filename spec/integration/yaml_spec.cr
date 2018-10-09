require "./spec_helper"
require "../../src/yaml"

describe YAML::Any do
  it "can be used as Crinja::Value" do
    env = Crinja.new

    any = YAML::Any.new({
      YAML::Any.new("bar") => YAML::Any.new("BAR!"),
    })
    env.from_string("{{ foo.bar }}: {{ baz }}").render({"foo" => any, "baz" => YAML::Any.new(1_i64)}).should eq "BAR!: 1"
  end
end

