# crinja

[![Build Status](https://travis-ci.org/straight-shoota/crinja.svg?branch=master)](https://travis-ci.org/straight-shoota/crinja)
[![Dependency Status](https://shards.rocks/badge/github/straight-shoota/crinja/status.svg)](https://shards.rocks/github/straight-shoota/crinja)
[![devDependency Status](https://shards.rocks/badge/github/straight-shoota/crinja/dev_status.svg)](https://shards.rocks/github/straight-shoota/crinja)

Crinja is an implementation of the [Jinja2 template engine](http://jinja.pocoo.org) written in [Crystal](http://crystallang.org). Templates are parsed and evaluated at runtime (see [Background](#background)). It includes a script runtime for evaluation of dynamic python-like expressions used by the Jinja2 syntax.

## Features

Crinja tries to stay close to the Jinja2 language design and implementation. It currently provides most features of the original template language, such as:

* all basic language features like control structures and expressions
* template inheritance
* block scoping
* custom tags, filters, functions, operators and tests
* autoescape by default

All standard [control structures (tags)](http://jinja.pocoo.org/docs/2.9/templates/#list-of-control-structures) and [operators](http://jinja.pocoo.org/docs/2.9/templates/#expressions) are already implemented, many implementations of standard [filters](http://jinja.pocoo.org/docs/2.9/templates/#list-of-builtin-filters), [tests](http://jinja.pocoo.org/docs/2.9/templates/#list-of-builtin-tests) and [global functions](http://jinja.pocoo.org/docs/2.9/templates/#list-of-global-functions) are still missing.

Currently, template errors fail fast raising an exception. It is considered to change this behaviour to collect multiple errors, similar to what Jinjava does.

### Missing features

* Line statements and line comments (don't seem to be particularly useful)
* sandboxed execution (on the roadmap)
* template caching (on the roadmap)
* configurable syntax
* extensions
* some detailed features like reusable blocks, macro API, macro caller

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

template = Crinja::Template.new("Hello, {{ name }}!")
template.render({"name" => "John"}) # => "Hello, John!"
```

### File loader

With this template file:
```html
# views/index.html.j2
<p>Hello {{ name | default('World') }}</p>
```

It can be loaded with a `FileSystemLoader`:

```crystal
require "crinja"

env = Crinja::Environment.new
env.loader = Crinja::Loader::FileSystemLoader.new("views/")
template = env.load("index.html.j2")
template.render # => "Hello, World!"
template.render({ "name" => "John" }) # => "Hello, John!"
```

## API

The API tries to stick ot the original [Jinja2 API](http://jinja.pocoo.org/docs/2.9/api/) which is written in Python.

### Configuration

Currently the following configuration options are supported:

<dl>
    <dt>autoescape</dt>
    <dd>
    <p>This config allows the same settings as <code><a href="http://jinja.pocoo.org/docs/2.9/api/#jinja2.select_autoescape">select_autoescape</a></code> in Jinja 2.9.</p>
    <p>It intelligently sets the initial value of autoescaping based on the filename of the template.</p>
    <p>When set to a boolean value, <code>false</code> deactivates any autoescape and <code>true</code> activates autoescape for any template.
    It also allows more detailed configuration:</p>
    <dl>
        <dt>enabled_extensions</dt>
        <dd>List of filename extensions that autoescape should be enabled for. Default: <code>["html", "htm", "xml"]</code></dd>
        <dt>disabled_extensions</dt>
        <dd>List of filename extensions that autoescape should be disabled for. Default: <code>[] of String</code></dd>
        <dt>default_for_string</dt>
        <dd>Determines autoescape default value for templates loaded from a string (without a filename). Default: <code>true</code></dd>
        <dt>default</dt>
        <dd>If nothing matches, this will be the default autoescape value. Default: <code>true</code></dd>
    </dl>
    <p>Note: <em>The default configuration of Crinja differs from that of Jinja 2.9, that autoescape is activated by default. This will most likely be changed by Jinja2 in the future, too.</em></p>
    </dd>
    <dt>keep_trailing_newline</dt>
    <dd>Preserve the trailing newline when rendering templates. If set to `false`, a single newline, if present, will be stripped from the end of the template. Default: <code>false</code></dd>
    <dt>trim_blocks</dt>
    <dd>If this is set to <code>true</code>, the first newline after a block is removed. This only applies to blocks, not expression tags. Default: <code>false</code>.</dd>
    <dt>lstrip_blocks</dt>
    <dd>If this is set to <code>true</code>, leading spaces and tabs are stripped from the start of a line to a block. Default: <code>false</code>.</dd>
</dl>

See also the original [Jinja2 API Documentation](http://jinja.pocoo.org/docs/2.9/api/).

### Custom features

You can provide custom tags, filters, functions, operators and tests. Create an implementation class that extends from `Crinja::Tag`, `Crinja::Filter`, `Crinja::Function`, `Crinja::Operator` or `Crinja::Test` and add an instance to the feature library in `env.context`.

Example:

```crystal
class MyCustomFilter < Crinja::Filter
    name "mycustom"
    arguments({
        :attribute => "great"
    })
    def call(target : Crinja::Value, arguments : Crinja::Callable::Arguments) : Crinja::Type
        "Crystal is #{arguments[:attribute]}! (orginally: #{target.to_s})"
    end
end

env.context.filters << MyCustomFilter.new
# Usage: {{ "Hello World" | mycustom(attribute="super") }}
```

## Background

Crystal is a great programming language with a clean syntax inspired by Ruby, but it is compiled and runs incredibly fast.

There are already some [template engines for crystal](https://github.com/veelenga/awesome-crystal#template-engine). But if you want control structures and dynamic expressions without some sort of Domain Specific Language, there is only [Embedded Crystal (ECR)](https://crystal-lang.org/api/0.21.1/ECR.html), which is a part of Crystal's standard library. It uses macros to convert templates to Crystal code and embed them into the source at compile time. So for every change in a template, you have to recompile the binary. This approach is certainly applicable for many projects and provides very fast template rendering. The downside is, you need a crystal build stack for template design. This makes it impossible to render dynamic, user defined templates, that can be changed at runtime.

Jinja2 is a powerful, mature template engine with a great syntax and proven language design. It was derived from the [Django Template Language](http://docs.djangoproject.com/en/dev/ref/templates/builtins/) and has quite a number of implementations and adaptations in other languages:

* [Jinjava](https://github.com/HubSpot/jinjava) - Jinja2 implementation in Java, but uses [Unified Expression Language](https://uel.java.net/) (`javaex.el`) instead of python-like expressions. It served as an inspiration for some parts of Crinja.
* [Liquid](https://shopify.github.io/liquid/) - Jinja2-inspired template engine in Ruby
* [Liquid.cr](https://github.com/TechMagister/liquid.cr) - Liquid implementation in Crystal
* [Twig](https://twig.sensiolabs.org/) - Jinja2-inspired template engine in PHP
* [ginger](https://hackage.haskell.org/package/ginger) - Jinja2 implementation in Haskell
* [Jinja-Js](https://github.com/sstur/jinja-js) - Jinja2-inspired template engin in Javascript
* [jigo](https://github.com/jmoiron/jigo) - Jinja2 implementation in Go

## Contributing

1. Fork it ( https://github.com/straight-shoota/crinja/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [straight-shoota](https://github.com/straight-shoota) Johannes Müller - creator, maintainer
