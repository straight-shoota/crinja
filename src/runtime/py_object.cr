# Include this module into your classes to make them available as values in Crinja.
# There are three types of properties you can expose to the Crinja runtime:
#
# 1. `#getattr(name : Crinja::Type) : Crinja::Type`: Access an attribute (e.g. an instance property) of this class.
# 2. `#__getitem__(name : Crinja::Type) : Crinja::Type`: Access an item (e.g. an array member) of this class.
# 3. `#__call__(name : String) : Crinja::Callable | Callable::Proc`: Expose a callable as method of this class.
#
# Through the static comilation it is not possible to access properties or methods of an object
# directly from inside the Crinja runtime. These methods allow to define a name-based lookup and
# return the corresponding values. If the looked-up name is not defined, the return value for `__call__`
# should be `nil`. If `getattr` or `__getitem__` return `nil`, this will be a valid return value.
#
# They *must* return an `Undefined` if there is no attribute or item of that name. In this case,
# `Crinja::Resolver` may try other methods of accessing the attribute or item depending on the type
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
#   def getattr(attr)
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
#         self.age.days.as(Crinja::Type)
#       end
#     end
#   end
# end
# ```
module Crinja::PyObject
  # This macro creates a lookup list for `getattr` including all publicly visible properties.
  macro getattr
    def getattr(attr : Crinja::Type) : Crinja::Type
      # TODO: Change from methods to instance variables
      {% for method in @type.methods %}
        {% if method.visibility == :public &&
                (method.name != "each" && method.name != "iterator") &&
                (method.block_arg.class_name == "Nop") &&
                # (method.return_type == Type || method.return_type.class_name == "Nop") &&
                (method.args.empty?) %}
          if {{ method.name.stringify }} == attr
            return Crinja.cast_type(self.{{ method.name }})
          end
        {% end %}
      {% end %}

      Undefined.new(attr.to_s)
    end
  end

  # This macro creates a lookup list for `getattr` including only whitelisted properties.
  macro getattr(*whitelist)
    def getattr(attr : Crinja::Type) : Crinja::Type
      {% for method in whitelist %}
        if {{ method.id.stringify }} == attr
          return Crinja.cast_type(self.{{ method.id }})
        end
      {% end %}

      Undefined.new(attr.to_s)
    end
  end
end
