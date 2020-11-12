require "./runtime/value"

# Method annotation used by `Crinja::Object::Auto` to expose the
# annotated method as property in the Crinja runtime.
annotation Crinja::Attribute
end

# Type annotation used by `Crinja::Object::Auto` to expose all
# methods defined in the annotated type as properties in the Crinja runtime.
annotation Crinja::Attributes
end

# This module can be included into custom types to make their instances available
# as values inside the Crinja runtime.
#
# There are three types of properties that can be exposed to the Crinja runtime:
#
# * `#crinja_attribute(name : Crinja::Value) : Crinja::Value`:
#   Access an attribute (e.g. an instance property) of this type.
# * `#crinja_item(name : Crinja::Value) : Crinja::Value`:
#   Access an item (e.g. an array member) of this type.
# * `#crinja_call(name : String) : Crinja::Callable | Callable::Proc | Nil`:
#   Expose a callable as method of this type.
#
# Through the static comilation it is not possible to access properties or methods of an object
# directly from inside the Crinja runtime. These methods allow to define a name-based lookup and
# return the corresponding values. If the looked-up name is not defined, the return value for `crinja_call`
# should be `nil`.  should return `Crinja::Undefined`.
#
# `crinja_attribute` and `crinja_item` *must* return an `Crinja::Undefined` if there is no attribute or item of that name.
# In this case, `Crinja::Resolver` may try other methods of accessing the attribute or item depending on the type
# of lookup (see [*Notes on Subscription*](http://jinja.pocoo.org/docs/2.9/templates/#notes-on-subscriptions) for Jinja2).
#
# Implementing classes *do not need* to implement these methods. They will only be accessed if an
# instance of `Crinja::Object` responds to them. Otherwise it will be considered as if there are no
# attributes, items or methods defined.
#
# Example:
#
# ```
# class User
#   include Crinja::Object
#
#   property name : String
#   property dob : Time
#
#   def initialize(@name, @dob)
#   end
#
#   def age
#     (Time.now - @dob).years
#   end
#
#   def crinja_attribute(attr : Crinja::Value) : Crinja::Value
#     value = case attr.to_string
#             when "name"
#               name
#             when "age"
#               age
#             else
#               Undefined.new(attr.to_s)
#             end
#
#     Crinja::Value.new(value)
#   end
#
#   def crinja_call(name : String) : Crinja::Callable | Crinja::Callable::Proc | Nil
#     if name == "days_old"
#       ->(arguments : Crinja::Arguments) do
#         self.age.days
#       end
#     end
#   end
# end
# ```
module Crinja::Object
  # When this module is included, it defines a `crinja_attribute` method (see `Crinja::Object` for its purpose)
  # with dynamic accessors to all methods exposed using an annotation.
  #
  # * `@[Crystal::Attribute]` (method annotation): Exposes the annotated method.
  #   Options:
  #   * `ignore`: Don't expose this method (useful to exclude specific methods from `Crystal::Attributes`)
  #   * `name`: Expose the method under a different name.
  # * `@[Crystal::Attributes]` (type annotation): Exposes all methods in the annotated type.
  #   Only methods with valid signatures are exposed (can be called without arguments).
  #   Options:
  #   * `expose`: A whitelist of methods to expose. If not defined, all methods will be exposed (unless the method itself is annotated as `@[Crinja::Attribute(ignore: true)]`)
  #
  # Example:
  # ```
  # @[Crinja::Attributes(expose: [name, age])]
  # class User
  #   include Crinja::Object::Auto
  #
  #   property name : String
  #   property dob : Time
  #
  #   def initialize(@name, @dob)
  #   end
  #
  #   def age
  #     (Time.now - @dob).year
  #   end
  # end
  module Auto
    include ::Crinja::Object

    def crinja_attribute(attr : ::Crinja::Value) : ::Crinja::Value
      {% begin %}
        {% exposed = [] of _ %}
        value = case attr.to_string
        {% for type in [@type] + @type.ancestors %}
          {% type_annotation = type.annotation(::Crinja::Attributes) %}
          {% expose_all = type_annotation && !type_annotation[:expose] %}
          {% if type_exposed = type_annotation && type_annotation[:expose] %}
            {% exposed = exposed + type_exposed.map &.id %}
          {% end %}
          {% for method in type.methods %}
            {% ann = method.annotation(::Crinja::Attribute) %}
            {% expose_this_method = (expose_all || ann || exposed.includes? method.name) && (!ann || !ann[:ignore]) %}
            {% if expose_this_method %}
              {% if method.name != "initialize" %}
                {% if !method.accepts_block? %}
                  {% if method.args.all? { |arg| arg.default_value.class_name != "Nop" } %}
                    {% method_name = (ann && ann[:name]) || method.name %}
                    {% if !(ann && ann[:name]) && method.name.ends_with?("?") %}
                      when "is_{{ method_name.id[0..-2] }}", {{ method_name.id[0..-2].stringify }}
                    {% else %}
                      when {{ method_name.id.stringify }}
                    {% end %}
                    self.{{ method.name.id }}
                  {% elsif ann %}
                    {% raise "Method #{method.name} annotated as @[Crinja::Attribute] cannot be called without arguments" %}
                  {% end %}
                {% elsif ann %}
                  {% raise "Method #{method.name} annotated as @[Crinja::Attribute] requires block" %}
                {% end %}
              {% elsif ann %}
                {% raise "Method #{method.name} annotated as @[Crinja::Attribute] has invalid name" %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
        else
          ::Crinja::Undefined.new(attr.to_s)
        end

        ::Crinja::Value.new(value)
      {% end %}
    end
  end
end
