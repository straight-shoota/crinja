require "../function"

class Crinja::Tag::For::ForLoop
  include PyObject

  getter iterator, length
  getter index0, revindex0, first, last

  getattr length, first, last, index, index0, revindex, revindex0, cycle

  @length : Int32 = Int32::MIN
  @revindex0 : Int32 = Int32::MIN

  def self.new(collection)
    new(collection.each, collection.size)
  end

  def initialize(iterator : Iterator(Value), @length : Int32)
    initialize(iterator)

    if length < 2
      @revindex0 = 1
      @last = true
    else
      @revindex0 = length
      @last = false
    end
  end

  def initialize(@iterator : Iterator(Value))
    @index0 = -1
    @first = true
    @last = false
  end

  def each
    value = iterator.next

    while true
      if value.is_a?(Iterator::Stop)
        break
      else
        @index0 += 1
        @revindex0 -= 1 unless @length == Int32::MIN

        next_value = iterator.next
        if next_value.is_a?(Iterator::Stop)
          @last = true
          @length = index
          @revindex0 = 0
        end

        yield value.as(Value)

        value = next_value

        @first = false
      end
    end
  end

  def index
    index0 + 1
  end

  def revindex
    revindex0 == Int32::MIN ? Int32::MIN : revindex0 + 1
  end

  def cycle
    CycleMethod.new(self)
  end

  class CycleMethod
    include Callable

    def initialize(@loop : ForLoop)
    end

    def call(arguments : Callable::Arguments) : Type
      arguments.varargs[@loop.index0 % arguments.varargs.size].raw
    end
  end

  class Recursive < ForLoop
    include Callable

    property depth0 : Int32 = 0

    # TODO: Explicit receiver `PyObject` is required because of a macro lookup bug (https://github.com/crystal-lang/crystal/issues/4639#issuecomment-314564447)
    PyObject.getattr depth, depth0

    @loop_runner : Crinja::Tag::For::Runner

    def initialize(loop_runner, collection)
      initialize(loop_runner, collection.each, collection.size)
    end

    def initialize(@loop_runner, iterator : Iterator(Value), length : Int32)
      super(iterator, length)
    end

    def initialize(@loop_runner, iterator : Iterator(Value))
      super(iterator)
    end

    def call(arguments : Callable::Arguments)
      sub_iterator = arguments.varargs.first

      sub_loop = self.class.new(@loop_runner, sub_iterator)
      sub_loop.depth0 = self.depth

      SafeString.build do |io|
        io << @loop_runner.run_loop(sub_loop).value
      end
    end

    def depth
      depth0 + 1
    end
  end
end
