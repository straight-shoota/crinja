class Crinja::Util::ScopeMap(K, V)
  @scope : Hash(K, V) = Hash(K, V).new
  @parent : self?

  getter parent, scope

  def initialize(@parent = nil, scope = nil)
    merge!(scope) unless scope.nil?
  end

  delegate :delete, :clear, :merge!, to: scope

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

  def []=(key : K, value : V)
    scope[key] = value
  end

  def undefined
    nil
  end

  def keys
    keys = scope.keys

    if p = parent
      keys += p.keys
    end

    keys
  end

  def values
    entries.map &.[0]
  end

  def entries
    keys.map do |key|
      {key, self[key]}
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
