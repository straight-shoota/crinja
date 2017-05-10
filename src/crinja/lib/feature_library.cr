abstract class Crinja::FeatureLibrary(T)
  class UnknownFeatureException < Crinja::RuntimeError
    def initialize(kind, name)
      super "no #{kind.name} with name \"#{name}\" registered"
    end
  end

  property store : Hash(String, T)

  # Creates a new feature library.
  # If *register_defaults* is set to `false`, this library will be empty. Otherwise it is populated
  # with registered default features.
  def initialize(register_defaults = true)
    @store = Hash(String, T).new
    self.register_defaults if register_defaults
  end

  delegate :each, :keys, to: store

  def register_defaults
  end

  macro register_defaults(defaults)
    def register_defaults
      register {{ defaults }}
    end
  end

  def register(classes : Array(Class))
    classes.each do |klass|
      self << klass.new
    end
  end

  def [](name : String) : T
    store[name.downcase]
  rescue
    raise UnknownFeatureException.new(T, name.downcase)
  end

  def <<(obj : T)
    store[obj.name] = obj
  end

  def []=(name : String, obj : T)
    store[name.downcase] = obj
  end

  def has_key?(name : String)
    store.has_key?(name.downcase)
  end

  def inspect(io : IO)
    store.inspect(io)
  end
end
