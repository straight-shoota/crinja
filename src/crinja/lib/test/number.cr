module Crinja
  class Test::Even < Test
    name "even"

    def call(target : Value, arguments : Arguments) : Bool
      target.to_i.even?
    end
  end

  class Test::Odd < Test
    name "odd"

    def call(target : Value, arguments : Arguments) : Bool
      target.to_i.odd?
    end
  end
end
