class Crinja::Util::ScopeMap(K, V)
  @scope : Hash(K, V) = Hash(K, V).new
  @parent : self?

  getter parent, scope

  def initialize(@parent = nil, scope = nil)
    merge!(scope) unless scope.nil?
  end

  delegate :[]=, :delete, :clear, :merge!, to: scope

  def size
    keys.size
  end

  def has_key?(key : K)
    scope.has_key?(key) || parent.try(&.has_key?(key))
  end

  def has_value?(value : V)
    if scope.has_value?
      return true
    end

    return parent.has_value?(value) unless parent.nil?

    return false
  end

  def [](key : K)
    if scope.has_key?(key)
      return scope[key]
    end

    parent.try(&.[key]) || undefined
  end

  def undefined
    nil
  end

  def keys
    keys = Set(K).new

    keys.merge!(parent.keys) unless parent.nil?

    keys.merge! scope.keys
  end

  def values
    entries.map &.[:value]
  end

  def entries
    keys.map do |key|
      {key: key, value: self[key]}
    end
  end

  def inspect(io : IO)
    io << "<"
    io << self.class.name
    io << " @scope="
    scope.inspect(io)

    unless parent.nil?
      io << " @parent="
      parent.inspect(io)
    end

    io << ">"
  end
end
