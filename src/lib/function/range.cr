Crinja.function({
  :start => 0,
  :stop  => 0,
  :step  => 1,
}, :range) do
  start = arguments[:start].as_number.to_i
  stop = arguments[:stop].as_number.to_i
  step = arguments[:step].as_number.to_i
  unless arguments.is_set?(:stop)
    stop = start
    start = arguments.default(:stop).as_number.to_i
  end

  # TODO: Use a stlib implementation or implement a custom sequence class. ::Range currently does
  # not support descending ranges.
  # start.step(to: stop, by: step).to_a.map(&.as(Type))
  Crinja::Function::RangeIterator(Int32, Int32).new(Range.new(start, stop, true), step).to_a.map(&.as(Type))
end

class Crinja::Function::RangeIterator(B, N)
  include Iterator(B)

  @range : Range(B, B)
  @step : N
  @current : B
  @reached_end : Bool
  @direction_reversed : Bool

  def initialize(@range, step, @current = range.begin, @reached_end = false)
    @step = step.abs
    @direction_reversed = step < 0
  end

  def next
    return stop if @reached_end

    if (@current <=> @range.end) == (@direction_reversed ? 1 : -1)
      value = @current
      if @direction_reversed
        @step.times { @current = @current.pred }
      else
        @step.times { @current = @current.succ }
      end
      value
    else
      @reached_end = true

      if !@range.excludes_end? && @current == @range.end
        @current
      else
        stop
      end
    end
  end

  def rewind
    @current = @range.begin
    @reached_end = false
    self
  end
end
