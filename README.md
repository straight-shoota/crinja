# crinja

[![Build Status](https://travis-ci.org/straight-shoota/crinja.svg?branch=master)](https://travis-ci.org/straight-shoota/crinja)
[![CircleCI](https://circleci.com/gh/straight-shoota/crinja.svg?style=svg)](https://circleci.com/gh/straight-shoota/crinja)
[![Dependency Status](https://shards.rocks/badge/github/straight-shoota/crinja/status.svg)](https://shards.rocks/github/straight-shoota/crinja)
[![devDependency Status](https://shards.rocks/badge/github/straight-shoota/crinja/dev_status.svg)](https://shards.rocks/github/straight-shoota/crinja)
[![Open Source Helpers](https://www.codetriage.com/straight-shoota/crinja/badges/users.svg)](https://www.codetriage.com/straight-shoota/crinja)

Crinja is an implementation of the [Jinja2 template engine](http://jinja.pocoo.org) written in [Crystal](http://crystallang.org). Templates are parsed and evaluated at runtime (see [Background](#background)). It includes a script runtime for evaluation of dynamic python-like expressions used by the Jinja2 syntax.

**[API Documentation](https://straight-shoota.github.io/crinja/api/latest/)** ·
**[Github Repo](https://github.com/straight-shoota/crinja)** ·
**[Template Syntax](https://github.com/straight-shoota/crinja/blob/master/TEMPLATE_SYNTAX.md)**

## Features

Crinja tries to stay close to the Jinja2 language design and implementation. It currently provides most features of the original template language, such as:

* all basic language features like control structures and expressions
* template inheritance
* block scoping
* custom tags, filters, functions, operators and tests
* autoescape by default
* template cache

From Jinja2 all builtin [control structures (tags)](http://jinja.pocoo.org/docs/2.9/templates/#list-of-control-structures), [tests](http://jinja.pocoo.org/docs/2.9/templates/#list-of-builtin-tests), [global functions](http://jinja.pocoo.org/docs/2.9/templates/#list-of-global-functions), [operators](http://jinja.pocoo.org/docs/2.9/templates/#expressions) and [filters](http://jinja.pocoo.org/docs/2.9/templates/#list-of-builtin-filters) have been ported to Crinja. See `Crinja::Filter`, `Crinja::Test`, `Crinja::Function`, `Crinja::Tag`, `Crinja::Operator` for lists of builtin features.

Currently, template errors fail fast raising an exception. It is considered to change this behaviour to collect multiple errors, similar to what Jinjava does.

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

Crinja.render("Hello, {{"{{"}} name }}!", {"name" => "John"}) # => "Hello, John!"
```

### File loader

With this template file:
```html
# views/index.html.j2
<p>Hello {{"{{"}} name | default('World') }}</p>
```

It can be loaded with a `FileSystemLoader`:

```crystal
require "crinja"

env = Crinja.new
env.loader = Crinja::Loader::FileSystemLoader.new("views/")
template = env.get_template("index.html.j2")
template.render # => "Hello, World!"
template.render({ "name" => "John" }) # => "Hello, John!"
```

### Crystal Playground

Run the **Crystal playground** inside this repostitory and the server is prepared with examples of using Crinja's API (check the `Workbooks` section).

```shell
$ crystal play
```

### Crinja Playground

The **Crinja Example Server** in [`examples/server`](https://github.com/straight-shoota/crinja/tree/master/examples/server) is an HTTP server which renders Crinja templates from `examples/server/pages`. It has also an interactive playground for Crinja template testing at `/play`.

```shell
$ cd examples/server && crystal server.cr
```

Other examples can be found in the [`examples` folder](https://github.com/straight-shoota/crinja/tree/master/examples).

## Template Syntax

The following is a quick overview of the template language to get you started.

More details can be found in **[the template guide](https://github.com/straight-shoota/crinja/blob/master/TEMPLATE_SYNTAX.md)**.
The original [Jinja2 template reference](http://jinja.pocoo.org/docs/2.9/templates/) can also be helpful, Crinja templates are mostly similar.

### Expressions

In a template, **expressions** inside double curly braces (`{{"{{"}}` ... `}}`) will be evaluated and printed to the template output.

Assuming there is a variable `name` with value `"World"`, the following template renders `Hello, World!`.

```html+jinja
Hello, {{"{{"}} name }}!
```

Properties of an object can be accessed by dot (`.`) or square brackets (`[]`). Filters modify the value of an expression.

```html+jinja
Hello, {{"{{"}} current_user.name | default("World") | titelize }}!
```

Tests are similar to filters, but are used in the context of a boolean expression, for example as condition of an `if` tag.

```html+jinja
{{"{%"}}% if current_user is logged_in %}
  Hello, {{"{{"}} current_user.name }}!
{{"{%"}}% else %}
  Hey, stranger!
{{"{%"}}% end %}
```

### Tags

**Tags** control the logic of the template. They are enclosed in `{{"{%"}}%` and `%}`.

```html+jinja
{{"{%"}}% if is_morning %}
  Good Moring, {{"{{"}} name }}!
{{"{%"}}% else %}
  Hello, {{"{{"}} name }}!
{{"{%"}}% end %}
```

The `for` tag allows looping over a collection.

```html+jinja
{{"{%"}}% for name in users %}
  {{"{{"}} user.name }}
{{"{%"}}% endfor %}
```

Other templates can be included using the `include` tag:

```html+jinja
{{"{%"}}% include "header.html" %}

<main>
  Content
</main>

{{"{%"}}% include "header.html" %}
```

### Macros

Macros are similar to functions in other programming languages.

```html+jinja
{{"{%"}}% macro say_hello(name) %}Hello, {{"{{"}} name | default("stranger") }}!{{"{%"}}% endmacro %}
{{"{{"}} say_hello('Peter') }}
{{"{{"}} say_hello('Paul') }}
```

### Template Inheritance
Templates inheritance enables the use of `block` tags in parent templates that can be overwritten by child templates. This is useful for implementating layouts:

```html+jinja
{# layout.html #}

<h1>{{"{%"}}% block page_title %}{{"{%"}}% endblock %}</h1>

<main>
  {{"{%"}}% block body}
    {# This block is typically overwritten by child templates #}
  {{"{%"}}% endblock %}
</main>

{{"{%"}}% block footer %}
  {{"{%"}}% include "footer.html" %}
{{"{%"}}% endblock %}
```

```html+jinja
{# page.html #}
{{"{%"}}% extends "layout.html" %}

{{"{%"}}% block page_title %}Blog Index{{"{%"}}% endblock %}
{{"{%"}}% block body %}
  <ul>
    {{"{%"}}% for article in articles if article.published %}
    <div class="article">
      <li>
        <a href="{{"{{"}} article.href | escape }}">{{"{{"}} article.title | escape }}</a>
        written by <a href="{{"{{"}} article.user.href | escape}}">{{"{{"}} article.user.username | escape }}</a>
      </li>
    {{"{%"}}%- endfor %}
  </ul>
{{"{%"}}% endblock %}
```

## Crystal API

The API tries to stick ot the original [Jinja2 API](http://jinja.pocoo.org/docs/2.9/api/) which is written in Python.

**[API Documentation](https://straight-shoota.github.io/crinja/api/latest/)**

### Configuration

Currently the following configuration options for `Config` are supported:

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
    <dd>Determines autoescape default value for templates loaded from a string (without a filename). Default: <code>false</code></dd>
    <dt>default</dt>
    <dd>If nothing matches, this will be the default autoescape value. Default: <code>false</code></dd>
  </dl>
  <p>Note: <em>The default configuration of Crinja differs from that of Jinja 2.9, that autoescape is activated by default for HTML and XML files. This will most likely be changed by Jinja2 in the future, too.</em></p>
  </dd>
  <dt>disabled_filters</dt>
  <dd>A list of *disabled_filters* that will raise a `SecurityError` when invoked.</dd>
  <dt>disabled_functions</dt>
  <dd>A list of *disabled_functions* that will raise a `SecurityError` when invoked.</dd>
  <dt>disabled_operators</dt>
  <dd>A list of *disabled_operators* that will raise a `SecurityError` when invoked.</dd>
  <dt>disabled_tags</dt>
  <dd>A list of *disabled_tags* that will raise a `SecurityError` when invoked.</dd>
  <dt>disabled_tests</dt>
  <dd>A list of *disabled_tests* that will raise a `SecurityError` when invoked.</dd>
  <dt>keep_trailing_newline</dt>
  <dd>Preserve the trailing newline when rendering templates. If set to `false`, a single newline, if present, will be stripped from the end of the template. Default: <code>false</code></dd>
  <dt>trim_blocks</dt>
  <dd>If this is set to <code>true</code>, the first newline after a block is removed. This only applies to blocks, not expression tags. Default: <code>false</code>.</dd>
  <dt>lstrip_blocks</dt>
  <dd>If this is set to <code>true</code>, leading spaces and tabs are stripped from the start of a line to a block. Default: <code>false</code>.</dd>
  <td>register_defaults</td>
  <dd>If <code>register_defaults</code> is set to <code>true</code>, all feature libraries will be populated with the defaults (Crinja standards and registered custom features).
  Otherwise the libraries will be empty. They can be manually populated with <code>library.register_defaults</code>.
  This setting needs to be set at the creation of an environment.</dd>
</dl>

See also the original [Jinja2 API Documentation](http://jinja.pocoo.org/docs/2.9/api/).

### Custom features

You can provide custom tags, filters, functions, operators and tests. Create an implementation using the macros `Crinja.filter`, `Crinja.function`, `Crinja.test`. They need to be passed a block which will be converted to a Proc. Optional arguments are a `Hash` or `NamedTuple` with default arguments and a name. If a name is provided, it will be added to the feature library defaults and available in every environment which uses the registered defaults.

Example with macro `Crinja.filter`:

```crystal
env = Crinja.new

myfilter = Crinja.filter({ attribute: nil }) do
  "#{target} is #{arguments["attribute"]}!"
end

env.filters["customfilter"] = myfilter

template = env.from_string(%({{"{{"}} "Hello World" | customfilter(attribute="super") }}))
template.render # => "Hello World is super!"
```

Or you can define a class for more complex features:
```crystal
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

env = Crinja.new
env.filters << Customfilter.new

template = env.from_string(%({{"{{"}} "Hello World" | customfilter(attribute="super") }}))
template.render # => "Hello World is super!"
```

Custom tags and operator can be implemented through subclassing `Crinja::Operator` and  `Crinja:Tag` and adding an instance to the feature library defaults (`Crinja::Operator::Library.defaults << MyTag.new`) or to a specific environment (`env.tags << MyTag.new`).

## Differences from Jinja2

This is an incomplete list of **Differences to the original Jinja2**:

* **Python expressions:** Because templates are evaluated inside a compiled Crystal program, it's not possible to use ordinary Python expressions in Crinja. But it might be considered to implement some of the Python stdlib like `Dict#iteritems()` which is often used to make dicts iterable.
* **Line statements and line comments**: Are not supported, because their usecase is negligible.
* **String representation:** Some objects will have slightly different representation as string or JSON. Crinja uses Crystal internals, while Jinja uses Python internals. For example, an array with strings like `{{"{{"}} ["foo", "bar"] }}` will render as `[u'foo', u'bar']` in Jinja2 and as `['foo', 'bar']` in Crinja.
* **Double escape:** `{{"{{"}} '<html>'|escape|escape }}` will render as `&lt;html&gt;` in Jinja2, but `&amp;lt;html&amp;gt;`. Should we change that behaviour?
* **Complex numbers**: Complex numbers are not supported yet.
* **Configurable syntax**: It is not possible to reconfigure the syntax symbols. This makes the parser less complex and faster.

The following features are not yet fully implemented, but on the [roadmap](ROADMAP.md):

* Sandboxed execution.
* Some in-depth features like extended macro reflection, reusable blocks.

## Background

Crystal is a great programming language with a clean syntax inspired by Ruby, but it is compiled and runs incredibly fast.

There are already some [template engines for crystal](https://github.com/veelenga/awesome-crystal#template-engine). But if you want control structures and dynamic expressions without some sort of Domain Specific Language, there is only [Embedded Crystal (ECR)](https://crystal-lang.org/api/0.21.1/ECR.html), which is a part of Crystal's standard library. It uses macros to convert templates to Crystal code and embed them into the source at compile time. So for every change in a template, you have to recompile the binary. This approach is certainly applicable for many projects and provides very fast template rendering. The downside is, you need a crystal build stack for template design. This makes it impossible to render dynamic, user defined templates, that can be changed at runtime.

Jinja2 is a powerful, mature template engine with a great syntax and proven language design. Its philosophy is:

> Application logic is for the controller, but don't make the template designer's life difficult by restricting functionality too much.

Jinja derived from the [Django Template Language](http://docs.djangoproject.com/en/dev/ref/templates/builtins/). While it comes from web development and is heavily used there ([Flask](http://flask.pocoo.org/))
[Ansible](https://ansible.com/) and [Salt](http://www.saltstack.com/) use it for dynamic enhancements of configuration data. It has quite a number of implementations and adaptations in other languages:

* [Jinjava](https://github.com/HubSpot/jinjava) - Jinja2 implementation in Java using [Unified Expression Language](https://uel.java.net/) (`javaex.el`) for expression resolving. It served as an inspiration for some parts of Crinja.
* [Liquid](https://shopify.github.io/liquid/) - Jinja2-inspired template engine in Ruby
* [Liquid.cr](https://github.com/TechMagister/liquid.cr) - Liquid implementation in Crystal
* [Twig](https://twig.sensiolabs.org/) - Jinja2-inspired template engine in PHP
* [ginger](https://hackage.haskell.org/package/ginger) - Jinja2 implementation in Haskell
* [Jinja-Js](https://github.com/sstur/jinja-js) - Jinja2-inspired template engin in Javascript
* [jigo](https://github.com/jmoiron/jigo) - Jinja2 implementation in Go
* [tera](https://github.com/Keats/tera) - Jinja2 implementation in Rust
* [jingoo](https://github.com/tategakibunko/jingoo) - Jinja2 implementation in OCaml
* [nunjucks](https://mozilla.github.io/nunjucks/) - Jinja2 inspired template engine in Javascript

## Contributing

1. Fork it (<https://github.com/straight-shoota/crinja/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [straight-shoota](https://github.com/straight-shoota) Johannes Müller - creator, maintainer
