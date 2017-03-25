module Crinja
  class Test::Even < Test
    name "even"

    def call(target : Any, arguments : Arguments) : Bool
      target.to_i.even?
    end
  end
end
