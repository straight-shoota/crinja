# crinja

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crinja:
    github: straight-shoota/crinja
```

## Usage

### Simple string template
```crystal
require "crinja"

template = Crinja::Template.new("Hello, {{ name | default('World') }}!")
template.render # "Hello, World!"
template.render({"name" => "John"}) # "Hello, John!"
```

### File loader
`views/index.html.j2`:
```<!DOCTYPE html>
<html>
<body>
    Hello {{ name | default('World') }}
</body>
</html>
```

```crystal
require "crinja"

env = Crinja::Environment.new
env.loader = Crinja::Loader::FileSystemLoader.new("views/")
template = env.load("index.html.j2")
template.render({"name" => "World"})
```

## Development


## Contributing

1. Fork it ( https://github.com/straight-shoota/crinja/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [straight-shoota](https://github.com/straight-shoota) Johannes Müller - creator, maintainer
