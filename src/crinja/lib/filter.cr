require "./function"
require "html"

module Crinja
  abstract class Filter < Function
    def call(arguments : Arguments) : Type
      call(arguments.target.not_nil!, arguments)
    end

    abstract def call(target : Any, arguments : Arguments) : Type

    class Library < FeatureLibrary(Filter)
      register_defaults [Abs, Float, Filesizeformat,
                         Uppercase, Lowercase, Capitalize, Center, Format, Indent,
                         Striptags,
                         Escape, Safe,
                         Dictsort,
                         List, Batch, Slice, First, Join,
                         Default]
    end
  end

  abstract class Test < Function
    def call(arguments : Arguments) : Type
      call(arguments.target.not_nil!, arguments)
    end

    abstract def call(target : Any, arguments : Arguments) : Bool

    class Library < FeatureLibrary(Test)
      register_defaults [Defined, Callable, Even, Odd]
    end

    macro test_def(name)
      class {{ name.stringify.capitalize.id }} < Test
        def name : String
          {{ name.stringify }}
        end

        def call(target : Any, arguments : Arguments) : Bool
          yield(target, arguments)
        end
      end

      #@@defaults << {{ name.stringify.capitalize.id }}
    end
  end
end

require "./filter/*"
require "./test/*"
