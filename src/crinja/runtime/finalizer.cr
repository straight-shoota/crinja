# This class is used to process the result of a variable expression before it is output.
# It tries to convert values to a meaningful string represenation similar to what `Object#to_s` does
# but with a few adjustments compared to Crystal standard `to_s` methods.
struct Crinja::Finalizer
  protected def self.stringify(raw, escape = false, in_struct = false)
    builder = new(escape, in_struct)
    builder.stringify(raw)
    builder.to_string
  end

  def initialize(@escape = false, @inside_struct = false)
    @io = IO::Memory.new
  end

  protected def to_string
    @io.to_s
  end

  # Convert a `Type` to stringitg.
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
        SafeString.escaped(string).to_s(@io)
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

  # Convert an `PyTuple` to string.
  protected def stringify(array : PyTuple)
    @inside_struct = true
    @io << "("
    array.join(", ", @io) { |item| stringify(item) }
    @io << ")"
  end

  private def quote
    quotes = @inside_struct
    @io << '"' if quotes
    yield
    @io << '"' if quotes
  end
end
