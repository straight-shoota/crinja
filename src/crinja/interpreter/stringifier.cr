class Crinja::Stringifier
  protected def self.stringify(raw, escape = false)
    builder = new(escape)
    builder.stringify(raw)
    builder.to_string
  end

  @inside_struct = false

  def initialize(@escape : Bool = false)
    @io = IO::Memory.new
  end

  protected def to_string
    @io.to_s
  end

  # Convert a `Type` to string.
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
