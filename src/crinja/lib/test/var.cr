module Crinja
  class Test::Defined < Test
    name "defined"

    def call(target : Any, arguments : Arguments) : Bool
      !target.undefined?
    end
  end

  class Test::Callable < Test
    name "callable"

    def call(target : Any, arguments : Arguments) : Bool
      target.callable?
    end
  end
end
