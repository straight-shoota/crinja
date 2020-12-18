# Introduction to Crinja Templates

The template features supported by Crinja are based on the [Jinja2 template language](http://jinja.pocoo.org) which is originally written in Python.

**[API Documentation](https://straight-shoota.github.io/crinja/api/latest/)** ·
**[Github Repo](https://github.com/straight-shoota/crinja)**

## Overview

Crinja template syntax can be embedded in any text content and individual templates features are enclosed in delimiters:

```html+jinja
{{ }} - print
{% %} - tag
{# #} - comment
```

When a template is rendered, **print statements** enclosed by double curly braces (`{{` ... `}}`) print their inner value to the template output.
Template **expressions** inside will be evaluated.

Assuming there is a variable `name` with value `"World"`, the following template expands to `Hello, World!`.

```html+jinja
Hello, {{ name }}!
```

**Tags** control the logic of the template. They are enclosed in `{%` and `%}`.

The `set` tag for example is used for assigments:
```html+jinja
{% set name = "John" %}
Hello, {{ name }}!
```

Most tags expect a content which spans between an opening tag and a closing tag. The latter has the same name name as the opening tag prefixed with `end`.
Tags can be nested.

```html+jinja
{% if name == "World" %}
Hello 🌍!
{% endif %}
```

**Comments** are enclosed in `{#` and `#}`. They are not parsed as template content and will not included in the template output.

## Variables

Template variables are defined in the context of each template.
Varibales can be populated externally by the application calling the template, or dynamically defined within.
The [`set` tag](#set-tag) allows to set or modify variables inside the template.

```html+jinja
{% set name = "World" %}
Hello, {{ name }}! -> Hello, World!
```

Members of objects can be traversed by a dot (`.`). `foo.bar` resolves the property `bar` of object `foo`.
Another option are square brackets (`[]`) where the name of the member equals to the value between the brackets. Above expression would be equal to `foo["bar"]`.

An empty value is expressed as `none`, similar to `nil` in Crystal.

If the value of a variable or expression simply does not exist at all, it will be *undefined*. Printing an undefined value will insert the empty string. In other contexts an undefined value might also be treated as empty or raise an error.

## Filters

Filters transform or alter a value. They are appended to any expression using a pipe symobl (`|`) followed by the name of the filter. `name | upper` applies the filter `upper` to the value of the variable `name`.

Arguments are added in parenthesis: `names | join(', ')`.

Filters can be chained and the outputs will be used in sequence:

```html+jinja
Hello, {{ name | default("World") | titelize }}! -> Hello, WORLD!
```

## Tests

Tests are conceptually similar to filters, but are used in the context of a boolean expression, for example as condition of an `if` tag.
Instead of a pipe they are applied using the keyword `is`.

For example, the expression `name is defined` returns `true` if the variable `name` is defined.

Test can accept arguments as well. If the test only takes one argument, the parentheses can be omitted: `9 is divisible by 3`.

```html+jinja
{% if current_user is logged_in %}
  Hello, {{ current_user.name }}!
{% else %}
  Hey, stranger!
{% end %}
```

## Tags

**Tags** control the logic of the template. They are enclosed in `{%` and `%}`.

```html+jinja
{% if is_morning %}
  Good Moring, {{ name }}!
{% else %}
  Hello, {{ name }}!
{% end %}
```

The `for` tag allows looping over a collection.

```html+jinja
{% for name in users %}
  {{ user.name }}
{% endfor %}
```

Other templates can be included using the `include` tag:

```html+jinja
{% include "header.html" %}

<main>
  Content
</main>

{% include "header.html" %}
```

## Macros

Macros can define re-usable template instructions that can be included in different places in the template.
They are similar to functions in other programming languages.

When a macro is called, the output produced by the macro is assigned as the return value of the expression.

```html+jinja
{# define macro: #}
{% macro say_hello(name) %}Hello, {{ name | default("stranger") }}!{% endmacro %}
{# invoke macro #}
{{ say_hello('Peter') }} -> Hello, Peter!

{# print to a variable #}
{% set hello_paul = say_hello('Paul') %}
{{ hello_paul }} -> Hello, Paul!

{# invoke with default value %}
{{ say_hello() }} -> Hello, stranger!
```

### Template Inheritance
Templates inheritance enables the use of `block` tags in parent templates that can be overwritten by child templates. This is useful for implementating layouts:

```html+jinja
{# layout.html #}

<h1>{% block page_title %}{% endblock %}</h1>

<main>
  {% block body %}
    {# This block is typically overwritten by child templates #}
  {% endblock %}
</main>

{% block footer %}
  {% include "footer.html" %}
{% endblock %}
```

```html+jinja
{# page.html #}
{% extends "layout.html" %}

{% block page_title %}Blog Index{% endblock %}
{% block body %}
  <ul>
    {% for article in articles if article.published %}
    <div class="article">
      <li>
        <a href="{{ article.href | escape }}">{{ article.title | escape }}</a>
        written by <a href="{{ article.user.href | escape}}">{{ article.user.username | escape }}</a>
      </li>
    {%- endfor %}
  </ul>
{% endblock %}
```
