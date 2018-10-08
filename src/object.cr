require "./runtime/py_object"
require "./runtime/value"

annotation Crinja::Attribute
end

annotation Crinja::Attributes
end

module Crinja::Object
  include Crinja::PyObject

  module Auto
    include Crinja::Object

    def getattr(attr : ::Crinja::Value) : ::Crinja::Value
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
                    when {{ ((ann && ann[:name]) || method.name).id.stringify }}
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
