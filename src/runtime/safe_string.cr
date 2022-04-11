require "html"

class Crinja
  struct SafeString
    def initialize(@string : String, @plain_value = false)
    end

    delegate :size, :to_i, :to_f, :to_s, :to_json, to: @string

    def inspect(io : IO)
      if @plain_value
        @string.to_s(io)
      else
        @string.inspect(io)
      end
    end

    def ==(other)
      @string == other
    end

    def [](index : Int)
      @string[index]
    end

    def [](*args)
      result = @string[*args]
      if result.is_a?(String)
        result = SafeString.new(result)
      end
      result
    end

    def []?(*args)
      result = @string[*args]
      if result.is_a?(String)
        result = SafeString.new(result)
      end
      result
    end

    def +(other : String | SafeString | Char)
      result = @string + other.to_s
      if other.is_a?(SafeString)
        result = SafeString.new(result)
      end
      result
    end

    def gsub(search, replace)
      result = @string.gsub(search, replace)

      if replace.is_a?(self)
        result = SafeString.new result
      end
      result
    end

    def partition(sep)
      a, b, c = @string.partition(sep)

      return SafeString.new(a), SafeString.new(b), SafeString.new(c)
    end

    def rpartition(sep)
      a, b, c = @string.rpartition(sep)

      return SafeString.new(a), SafeString.new(b), SafeString.new(c)
    end

    def sub(search, replace)
      result = @string.sub(search, replace)

      if replace.is_a?(self)
        result = SafeString.new result
      end
      result
    end

    def sub(search)
      all_safe = true

      result = @string.sub(search) do
        replace = yield
        if replace.is_a?(self)
          all_safe = false
        end
        replace
      end

      if all_safe
        result = SafeString.new result
      end

      result
    end

    def strip(*args)
      SafeString.new @string.strip(*args)
    end

    def lstrip(*args)
      SafeString.new @string.lstrip(*args)
    end

    def rstrip(*args)
      SafeString.new @string.rstrip(*args)
    end

    def each_line(chomp = true)
      @string.each_line(chomp) do |line|
        yield SafeString.new(line)
      end
    end

    def self.build
      new(String.build do |io|
        yield io
      end)
    end

    # for literals such as numbers or booleans, will not be wrapped in quotes by inspect
    def self.plain(value)
      new(value.to_s, true)
    end

    NIL = plain(nil)

    # Escapes value and wraps it in a `SafeString`.
    def self.escape(value : Value) : SafeString
      escape(value.raw)
    end

    # :ditto:
    def self.escape(value : Nil)
      NIL
    end

    # :ditto:
    def self.escape(value : SafeString)
      value
    end

    # :ditto:
    def self.escape(value : Number)
      plain value.to_s
    end

    # :ditto:
    def self.escape(value : Array)
      container = value.map do |v|
        escape(v).as(SafeString)
      end
      plain container.to_s
    end

    # :ditto:
    def self.escape(value : Hash)
      hash = value.each_with_object(Hash(SafeString, SafeString).new) do |(k, v), memo|
        memo[escape(k)] = escape(v)
      end
      plain hash.to_s
    end

    # :ditto:
    def self.escape(string)
      new HTML.escape string.to_s
    end

    # Yields a builder which automatically escapes.
    #
    # TODO: Implement stream IO.
    def self.escape
      string = String.build { |io| yield io }
      escape string
    end
  end
end
