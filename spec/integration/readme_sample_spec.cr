require "../spec_helper.cr"

private class Customfilter
  include Crinja::Callable
  getter name = "customfilter"

  getter defaults : Crinja::Variables = Crinja::Bindings.cast_variables({
    attribute: "great",
  })

  def call(arguments)
    "#{arguments.target} is #{arguments[:attribute]}!"
  end
end

describe "README.md" do
  it "example code works" do
    env = Crinja::Environment.new

    env.filters << Customfilter.new

    env.from_string("{{ 'foo' | customfilter }}").render.should eq "foo is great!"
  end
end
