require "./function"
require "html"

module Crinja
  abstract class Filter < Function
    def call(arguments : Arguments) : Type
      call(arguments.target.not_nil!, arguments)
    end

    abstract def call(target : Any, arguments : Arguments) : Type

    class Library < FeatureLibrary(Filter)
      register_defaults [Abs, Float,
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
      register_defaults [Even]
    end
  end
end

require "./filter/*"
require "./test/*"
