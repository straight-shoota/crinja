struct Crinja::SafeString
  def initialize(@string : String, @plain_value = false)
  end

  forward_missing_to string

  def to_s(io : IO)
    @string.to_s(io)
  end

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

  def self.build
    new(String.build do |io|
      yield io
    end)
  end

  # for literals such as numbers or booleans, will not be wrapped in quotes by inspect
  def self.plain(value)
    new(value.to_s, true)
  end

  SUBSTITUTIONS = {
    '>' => "&gt;",
    '<' => "&lt;",
    '&' => "&amp;",
    '"' => "&quot;",
  }

  def self.escape(value : Value) : SafeString
    escape(value.raw)
  end

  def self.escape(value : Type) : SafeString
    case value
    when nil
      SafeString.plain nil
    when SafeString
      value
    when Number
      SafeString.plain value.to_s
    when Array
      container = value.map do |v|
        escape(v).as(SafeString)
      end
      SafeString.plain container.to_s
    when Hash
      hash = value.each_with_object(Hash(SafeString, SafeString).new) do |(k, v), memo|
        memo[escape(k)] = escape(v)
      end
      SafeString.plain hash.to_s
    else
      new value.to_s.gsub(SUBSTITUTIONS)
    end
  end
end
