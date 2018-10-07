require "html"

# This class is used to process the result of a variable expression before it is output.
# It tries to convert values to a meaningful string represenation similar to what `Object#to_s` does
# but with a few adjustments compared to Crystal standard `to_s` methods.
struct Crinja::Finalizer
  def self.stringify(raw, escape = false, in_struct = false)
    String.build do |io|
      stringify(io, raw, escape, in_struct)
    end
  end

  def self.stringify(io : IO, raw, escape = false, in_struct = false)
    new(io, escape, in_struct).stringify(raw)
  end

  # :nodoc:
  protected def initialize(@io : IO, @escape = false, @inside_struct = false)
  end

  # Convert a `Value` to string.
  protected def stringify(value : Value)
    stringify(value.raw)
  end

  # Convert any type to string.
  protected def stringify(raw)
    raw.to_s(@io)
  end

  # Convert a `nil` to `"none"`.
  protected def stringify(raw : Nil)
    @io << "none"
  end

  # Convert a `SafeString` to string.
  protected def stringify(safe : SafeString)
    quote { safe.to_s(@io) }
  end

  # Convert a `SafeString` to string.
  protected def stringify(string : String)
    quote do
      if @escape
        HTML.escape(string).to_s(@io)
      else
        string.to_s(@io)
      end
    end
  end

  # Convert an `Array` to string.
  protected def stringify(array : Array)
    @inside_struct = true
    @io << "["
    array.join(", ", @io) { |item| stringify(item) }
    @io << "]"
  end

  # Convert an `Hash` to string.
  protected def stringify(hash : Hash)
    @inside_struct = true
    @io << "{"
    found_one = false
    hash.each do |key, value|
      @io << ", " if found_one
      stringify(key)
      @io << " => "
      stringify(value)
      found_one = true
    end
    @io << "}"
  end

  # Convert an `Crinja::Tuple` to string.
  protected def stringify(array : Crinja::Tuple)
    @inside_struct = true
    @io << "("
    array.join(", ", @io) { |item| stringify(item) }
    @io << ")"
  end

  private def quote
    quotes = @inside_struct
    @io << '\'' if quotes
    yield
    @io << '\'' if quotes
  end
end
