# Custom features

You can provide custom tags, filters, functions, operators and tests. Create an implementation using the macros `Crinja.filter`, `Crinja.function`, `Crinja.test`. They need to be passed a block which will be converted to a Proc. Optional arguments are a `Hash` or `NamedTuple` with default arguments and a name. If a name is provided, it will be added to the feature library defaults and available in every environment which uses the registered defaults.

Example with macro `Crinja.filter`:

```crystal
require "./crinja"
env = Crinja.new

myfilter = Crinja.filter({ attribute: nil }) do
  "#{target} is #{arguments["attribute"]}!"
end

env.filters["customfilter"] = myfilter

template = env.from_string(%({{ "Hello World" | customfilter(attribute="super") }}))
puts template.render
```

Or you can define a class for more complex features:

```crystal
require "./crinja"
env = Crinja.new

class Customfilter
  include Crinja::Callable

  getter name = "customfilter"

  getter defaults = Crinja.variables({
    "attribute" => "great"
  })

  def call(arguments)
    "#{arguments.target} is #{arguments["attribute"]}!"
  end
end
env.filters << Customfilter.new

template = env.from_string(%({{ "Hello World" | customfilter(attribute="super") }}))
puts template.render
```
