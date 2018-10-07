# Include this module into your classes to make them available as values in Crinja.
# There are three types of properties you can expose to the Crinja runtime:
#
# 1. `#crinja_attribute(name : Crinja::Value) : Crinja::Value`: Access an attribute (e.g. an instance property) of this class.
# 3. `#__call__(name : String) : Crinja::Callable | Callable::Proc`: Expose a callable as method of this class.
#
# Through the static comilation it is not possible to access properties or methods of an object
# directly from inside the Crinja runtime. These methods allow to define a name-based lookup and
# return the corresponding values. If the looked-up name is not defined, the return value for `__call__`
# should be `nil`.
#
# `crinja_attribute` *must* return an `Undefined` if there is no attribute or item of that name as `nil` is a valid return
# value that will be automatically wrapped in `Crinja::Value`.
# When it returnes undefined, `Crinja::Resolver` may try other methods of accessing the attribute or item depending on the type
# of lookup (see [*Notes on Subscription*](http://jinja.pocoo.org/docs/2.9/templates/#notes-on-subscriptions) for Jinja2).
#
# Implementing classes *do not need* to implement these methods. They will only be accessed if an
# instance of `PyObject` responds to them. Otherwise it will be considered as if there are no
# attributes, items or methods defined.
#
# Example:
#
# ```
# class User
#   include Crinja::PyObject
#
#   property name : String
#   property dob : Time
#
#   def initialize(@name, @dob)
#   end
#
#   def age
#     (Time.now - @dob)
#   end
#
#   def crinja_attribute(attr)
#     case attr
#     when "name"
#       name
#     when "age"
#       age.days / 365
#     else
#       Undefined.new(attr.to_s)
#     end
#   end
#
#   def __call__(name)
#     if name == "days_old"
#       ->(arguments : Crinja::Arguments) do
#         self.age.days
#       end
#     end
#   end
# end
# ```
module Crinja::PyObject
  # This macro creates a lookup list for `crinja_attribute` including all publicly visible properties.
  macro crinja_attribute
    def crinja_attribute(attr : Crinja::Value) : Crinja::Value
      # TODO: Change from methods to instance variables
      {% begin %}
        value = case attr.to_string
          {% for method in @type.methods %}
            {% if method.visibility == :public &&
                    (method.name != "each" && method.name != "iterator") &&
                    (method.block_arg.class_name == "Nop") &&
                    # (method.return_type == Value || method.return_type.class_name == "Nop") &&
                    (method.args.empty?) %}
              when {{ method.name.stringify }}
                self.{{ method.name }}
            {% end %}
          {% end %}
          else
            Crinja::Undefined.new(attr.to_s)
          end
      {% end %}

      Crinja::Value.new(value)
    end
  end

  # This macro creates a lookup list for `crinja_attribute` including only whitelisted properties.
  macro crinja_attribute(*whitelist)
    def crinja_attribute(attr : Crinja::Value) : Crinja::Value
      {% begin %}
        value = case attr.to_string
        {% for method in whitelist %}
          when {{ method.id.stringify }}
              self.{{ method.id }}
        {% end %}
        else
          Crinja::Undefined.new(attr.to_s)
        end
      {% end %}

      Crinja::Value.new(value)
    end
  end
end
