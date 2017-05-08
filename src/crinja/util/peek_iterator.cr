module Crinja::Util
  class PeekIterator(T)
    include Iterator(T)

    def initialize(@indexable : Indexable(T))
      @curr_pos = -1
    end

    def next?
      @curr_pos += 1
      at? @curr_pos
    end

    def next
      @curr_pos += 1
      at @curr_pos
    end

    def at?(pos)
      if pos >= @indexable.size || pos < 0
        return nil
      end

      @indexable[pos]
    end

    def at(pos)
      ret = at?(pos)

      raise "Unexpected end of iterator" if ret.nil?
      ret
    end

    def peek?(n = 1)
      at?(@curr_pos + n)
    end

    def peek(n = 1)
      at(@curr_pos + n)
    end
  end
end
