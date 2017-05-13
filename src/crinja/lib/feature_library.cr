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

  # Adds default values to this library.
  def register_defaults; end

  macro inherited
    # Create a local method in a subclass to allow the usage of `previous_def`.
    def register_defaults; end
  end

  # Register default values with this library.
  macro register_default(default, name = nil)
    def register_defaults
      previous_def
      {% if name.is_a?(NilLiteral) %}
      self << {{ default }}
      {% else %}
      self[{{ name }}] = {{ default }}
      {% end %}
    end
  end

  # Adds an array of classes to this library.
  def <<(classes : Array(Class))
    classes.each do |klass|
      self << klass
    end
  end

  # Adds a class to this library.
  def <<(klass : Class)
    if klass.responds_to?(:new)
      self << klass.new
    else
      self << klass
    end
  end

  # Adds a feature object to this library.
  # It will be stored under the key `obj.name`.
  def <<(obj : T)
    store[obj.name] = obj
  end

  # Retrieves the feature object in this library with key *name*.
  def [](name : String) : T
    store[name.downcase]
  rescue
    raise UnknownFeatureException.new(T, name.downcase)
  end

  # Stores a feature object *obj* under the key *name*.
  def []=(name : String, obj : T)
    store[name.downcase] = obj
  end

  # Stores a feature object *obj* under the key *name*.
  def []=(name : String, klass : Class)
    store[name.downcase] = klass.new
  end

  def has_key?(name : String)
    store.has_key?(name.downcase)
  end

  def inspect(io : IO)
    store.inspect(io)
  end
end
