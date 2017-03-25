module Crinja
  class Function::Range < Function
    name "range"

    arguments({
      :start => 0,
      :stop  => 0,
      :step  => 1,
    })

    def call(arguments : Arguments) : Type
      stop = arguments[:stop].to_i
      start = arguments[:start].to_i
      step = arguments[:step].to_i
      unless arguments.is_set?(:stop)
        stop = arguments.varargs.first.to_i
        start = arguments.default(:stop).to_i
      end

      ::Range.new(start, stop, true).step(step).to_a.map(&.as(Type))
    end
  end
end
