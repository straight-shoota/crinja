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
    macro create_filter(*args)
      Crinja.create_filter({{ *args }})
    end
  end

  abstract class Test < Function
    class Library < FeatureLibrary(Test)
    end

    # This is a convenient alias for `Crinja.create_test`.
    macro create_test(*args)
      Crinja.create_test({{ *args }})
    end
  end

  macro create_feature(name, kind, *expressions)
    {% klassname = name.stringify.capitalize.id %}
    class {{ klassname }} < {{ kind }}
      def name
        {{ name.stringify.downcase }}
      end

      {% for expression in expressions %}
        {% if expression.is_a?(HashLiteral) %}
          arguments({{ expression }})
        {% elsif expression.is_a?(NamedTupleLiteral) %}
          # transfer NamedTupleLiteral to HashLiteral
          arguments({
            {% for key in expression.keys %}
              {{ key }} => {{ expression[key] }}
            {% end %}
            })
        {% end %}
      {% end %}

      def call(arguments : Arguments) : Type
        {% for expression in expressions %}
          {{ expression unless expression.is_a?(HashLiteral | NamedTupleLiteral) }}
        {% end %}
      end

      # TODO: Remove
      def call(target : Value, arguments : Arguments) : Type; end
    end

    {{ kind }}.register_default {{ klassname }}
  end

  # This macro creates a simple boilerplate test implementation class.
  # *name* is the name of the test as type id.
  # *expression* will be inserted into the `#call` method. Available local variables are:
  # * *arguments*: `Arguments` object provided to the call
  # * *target*: `Value` which is the target of this test (conveniently extracted from *arguments*)
  macro create_test(name, *expressions)
    Crinja.create_feature({{ name }}, Crinja::Test, target = arguments.target.not_nil!, {{ *expressions }})
  end

  # This macro creates a simple boilerplate filter implementation class.
  # *name* is the name of the filter as type id.
  # *expression* will be inserted into the `#call` method. Available local variables are:
  # * *arguments*: `Arguments` object provided to the call
  # * *target*: `Value` which is the target of this filter (conveniently extracted from *arguments*)
  macro create_filter(name, *expressions)
    Crinja.create_feature({{ name }}, Crinja::Filter, target = arguments.target.not_nil!, {{ *expressions }})
  end
end

require "./filter/*"
require "./test/*"
