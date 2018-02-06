# Using custom objects

To make custom objects usable in Crinja, they need to include `Crinja::PyObject`.

> This module does not define any methods or requires a specific interface, it is necessary because Crystal cannot use `Object` as type of an instance variable.

Classes *may* implement the following methods to make properties accessbile:

1. `#getattr(name : Crinja::Type) : Crinja::Type`: Access an attribute (e.g. an instance property) of this class.
2. `#__getitem__(name : Crinja::Type) : Crinja::Type`: Access an item (e.g. an array member) of this class.
3. `#__call__(name : String) : Crinja::Callable | Callable::Proc`: Expose a callable as method of this class.

They *must* return an `Undefined` if there is no attribute or item of that name.

```playground
require "./crinja"

class User
  include PyObject

  property name : String
  property dob : Time

  def initialize(@name, @dob)
  end

  def age
    Time.now - @dob
  end

  def getattr(attr)
     case attr
     when "name"
       name
     when "age"
       age.days / 365
     else
       Undefined.new(attr.to_s)
     end
  end
end

users = [
  User.new("john", Time.new(1982, 10, 10)),
  User.new("bob", Time.new(1997, 9, 16)),
  User.new("peter", Time.new(2002, 4, 1))
]

env = Crinja.new

template = env.from_string <<-'TEMPLATE'
  {%- for user in users -%}
  *  {{ user.name }} ({{ user.age }})
  {% endfor -%}
  TEMPLATE

puts template.render({users: users})
```
