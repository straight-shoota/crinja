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

  # :nodoc:
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

  # This macro returns a `Crinja::Callable` proc which implements a `Crinja::Test`.
  #
  # *defaults* are set as default values in the `Crinja::Arguments` object,
  # which a call to this proc receives.
  #
  # If a *name* is provided, the created proc will automatically be registered as a default test
  # at `Crinja::Test::Library`.
  #
  # The macro takes a *block* which will be the main body for the proc. There, the following
  # variables are available:
  # * *arguments* : `Crinja::Arguments` - Call arguments from the caller including *defaults*.
  # * *env* : `Crinja::Environment` - The current environment.
  # * *target* : `Crinja::Value` - The subject of the test. Short cut for `arguments.target`.
  macro test(defaults = nil, name = nil, &block)
    Crinja.callable(Crinja::Test, {{ defaults }}, {{ name }}) do
      target = arguments.target!
      ({{ block.body }}).as(Crinja::Type)
    end
  end

  # This macro returns a `Crinja::Callable` proc which implements a `Crinja::Filter`.
  #
  # *defaults* are set as default values in the `Crinja::Arguments` object,
  # which a call to this proc receives.
  #
  # If a *name* is provided, the created proc will automatically be registered as a default filter
  # at `Crinja::Filter::Library`.
  #
  # The macro takes a *block* which will be the main body for the proc. There, the following
  # variables are available:
  # * *arguments* : `Crinja::Arguments` - Call arguments from the caller including *defaults*.
  # * *env* : `Crinja::Environment` - The current environment.
  # * *target* : `Crinja::Value` - The value which is to be filtered. Short cut for `arguments.target`.
  macro filter(defaults = nil, name = nil, &block)
    Crinja.callable(Crinja::Filter, {{ defaults }}, {{ name }}) do
      target = arguments.target!
      ({{ yield }}).as(Crinja::Type)
    end
  end

  # This macro returns a `Crinja::Callable` proc which implements a `Crinja::Function`.
  #
  # *defaults* are set as default values in the `Crinja::Arguments` object,
  # which a call to this proc receives.
  #
  # If a *name* is provided, the created proc will automatically be registered as a default golbal
  # function at `Crinja::Function::Library`.
  #
  # The macro takes a *block* which will be the main body for the proc. There, the following
  # variables are available:
  # * *arguments* : `Crinja::Arguments` - Call arguments from the caller including *defaults*.
  # * *env* : `Crinja::Environment` - The current environment.
  macro function(defaults = nil, name = nil, &block)
    Crinja.callable(Crinja::Function, {{ defaults }}, {{ name }}) do
      ({{ yield }}).as(Crinja::Type)
    end
  end
end

require "./function/*"
require "./filter/*"
require "./test/*"
