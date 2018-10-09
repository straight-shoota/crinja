# Using custom objects

To make custom objects usable in Crinja, they need to include `Crinja::Object`.

> This module does not define any methods or requires a specific interface, it is just necessary to have a dedicated
  type for this because Crystal cannot use `Object` as type of an instance variable (yet).

Types *may* implement the following methods to make properties accessbile:

* `#crinja_attribute(name : Crinja::Value) : Crinja::Value`:
   Access an attribute (e.g. an instance property) of this type.
* `#crinja_call(name : String) : Crinja::Callable | Callable::Proc | Nil`:
   Expose a callable as method of this type.

`crinja_attribute` *must* return an `Crinja::Undefined` if there is no attribute or item of that name. `crinja_call` returns `nil` in that case.

## Example

```crystal
require "./crinja"

class User
  include Crinja::Object

  property name : String
  property dob : Time

  def initialize(@name, @dob)
  end

  def age
    (Time.now - @dob).years
  end

  def crinja_attribute(attr : Crinja::Value)
    value = case attr.to_string
            when "name"
              name
            when "age"
              age
            else
              Crinja::Undefined.new(attr.to_s)
            end

    Crinja::Value.new(value)
  end
end

users = [
  User.new("john", Time.new(1982, 10, 10)),
  User.new("bob", Time.new(1997, 9, 16)),
  User.new("peter", Time.new(2002, 4, 1))
]

Crinja.render STDOUT, <<-'TEMPLATE', {users: users}
  {{"{%"}}%- for user in users -%}
  *  {{"{{"}} user.name }} ({{"{{"}} user.age }})
  {{"{%"}}% endfor -%}
  TEMPLATE
```

# Automatic exposure

The method definition of `crinja_attribute` is often pretty boring as it usually just maps names of methods to the respective method calls.

This can easily be generated automatically by the use of `Crinja::Object::Auto`. This module defines an automatically generated `crinja_attribute` method that exposes the types method as attributes.

A method will be exposed if it is annotated with `@[Crystal::Attribute]`.

A type annotated with `@[Crystal::Attributes]` exposes all methods defined on that type and matching the signature (no argument, no block).
This annotation take an optional `expose` argument which whitelist methods to expose.

```crystal
@[Crinja::Attributes(expose: [name, age])]
class User
  include Crinja::Object::Auto

  property name : String
  property dob : Time

  def initialize(@name, @dob)
  end

  def age
    (Time.now - @dob).years
  end
end

users = [
  User.new("john", Time.new(1982, 10, 10)),
  User.new("bob", Time.new(1997, 9, 16)),
  User.new("peter", Time.new(2002, 4, 1))
]

Crinja.render STDOUT, <<-'TEMPLATE', {users: users}
  {{"{%"}}%- for user in users -%}
  *  {{"{{"}} user.name }} ({{"{{"}} user.age }})
  {{"{%"}}% endfor -%}
  TEMPLATE
```
