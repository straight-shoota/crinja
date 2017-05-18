require "./callable"
require "./feature_library"

module Crinja
  module Function
    class Library < FeatureLibrary(Callable)
    end
  end

  class Filter
    class Library < FeatureLibrary(Callable)
    end
  end

  module Test
    class Library < FeatureLibrary(Callable)
    end
  end

  macro callable(kind, defaults = nil, name = nil)
    %defaults = Hash(::String, Crinja::Type).new
    {% if defaults.is_a?(NamedTupleLiteral) || defaults.is_a?(HashLiteral) %}
    {% for key in defaults.keys %}
      %defaults[{{ key.id.stringify }}] = {{ defaults[key] }}
    {% end %}
    {% else %}
      {% name = defaults %}
    {% end %}

    %block = ->(arguments : Crinja::Arguments) do
      arguments.defaults = %defaults
      {% if defaults.is_a?(NamedTupleLiteral) || defaults.is_a?(HashLiteral) %}
      {% for key in defaults.keys %}
        {{ key.id }} = arguments[{{ key.id.symbolize }}]
      {% end %}
      {% end %}
      env = arguments.env
      ({{ yield }}).as(Crinja::Type)
    end

    {% if defaults.is_a?(StringLiteral) %}
      {% name = defaults %}
    {% end %}

    {% unless name.is_a?(NilLiteral) %}
    {{ kind }}::Library.defaults[{{ name.id.stringify }}] = %block
    {% end %}

    %block
  end

  # This macro creates a test implementation proc.
  macro test(defaults = nil, name = nil)
    Crinja.callable(Crinja::Test, {{ defaults }}, {{ name }}) do
      target = arguments.target!
      ({{ yield }}).as(Crinja::Type)
    end
  end

  macro filter(defaults = nil, name = nil)
    Crinja.callable(Crinja::Filter, {{ defaults }}, {{ name }}) do
      target = arguments.target!
      ({{ yield }}).as(Crinja::Type)
    end
  end

  macro function(defaults = nil, name = nil)
    Crinja.callable(Crinja::Function, {{ defaults }}, {{ name }}) do
      ({{ yield }}).as(Crinja::Type)
    end
  end
end

require "./function/*"
require "./filter/*"
require "./test/*"
