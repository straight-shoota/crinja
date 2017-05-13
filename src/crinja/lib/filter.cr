require "./function"
require "html"

module Crinja
  abstract class Filter < Function
    def call(arguments : Arguments) : Type
      call(arguments.target.not_nil!, arguments)
    end

    abstract def call(target : Value, arguments : Arguments) : Type

    class Library < FeatureLibrary(Filter)
      register_default [
        List, Batch, Slice, First, Join,
        Default,
      ]
    end

    # This is a convenient alias for `Crinja.create_filter`.
    macro create_filter(klass, defaults = nil, name = nil, default = false)
      Crinja.create_filter({{ klass }}, {{ defaults }}, {{ name }}, {{ default }}) { {{ yield }} }
    end
  end

  abstract class Test < Function
    class Library < FeatureLibrary(Test)
    end

    # This is a convenient alias for `Crinja.create_test`.
    macro create_test(klass, defaults = nil, name = nil, default = false)
      Crinja.create_test({{ klass }}, {{ defaults }}, {{ name }}, {{ default }}) { {{ yield }} }
    end
  end

  macro create_feature(kind, klass = nil, arguments = nil, name = nil, register_default = false)
    {% klassname = klass.stringify.capitalize.id %}
    class {{ klassname }} < {{ kind }}
      {% unless name.is_a?(NilLiteral) %}
      def name
        {{ name.stringify.downcase }}
      end
      {% end %}

      {% unless arguments.is_a?(NilLiteral) %}
        arguments({{ arguments }})
      {% end %}

      def call(arguments : ::Crinja::Callable::Arguments) : ::Crinja::Type
        {{ yield }}
      end

      # TODO: Remove
      def call(target : ::Crinja::Value, arguments : ::Crinja::Callable::Arguments) : ::Crinja::Type; end
    end

    {% if register_default %}
    {{ kind }}.register_default {{ klassname }}
    {% end %}
  end

  # This macro creates a simple boilerplate test implementation class.
  # *klass* is the name of the test as type id.
  # *expression* will be inserted into the `#call` method. Available local variables are:
  # * *arguments*: `Arguments` object provided to the call
  # * *target*: `Value` which is the target of this test (conveniently extracted from *arguments*)
  macro create_test(klass, defaults = nil, name = nil, default = false)
    ::Crinja.create_feature(::Crinja::Test, {{ klass }}, {{ defaults }}, {{ name }}, {{ default }}) do
      target = arguments.target.not_nil!
      {{ yield }}
    end
  end

  # This macro creates a simple boilerplate filter implementation class.
  # *klass* is the klass of the filter as type id.
  # *expression* will be inserted into the `#call` method. Available local variables are:
  # * *arguments*: `Arguments` object provided to the call
  # * *target*: `Value` which is the target of this filter (conveniently extracted from *arguments*)
  macro create_filter(klass, defaults = nil, name = nil, default = false)
    ::Crinja.create_feature(::Crinja::Filter, {{ klass }}, {{ defaults }}, {{ name }}, {{ default }}) do
      target = arguments.target.not_nil!
      {{ yield }}
    end
  end
end

require "./filter/*"
require "./test/*"
