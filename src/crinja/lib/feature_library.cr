abstract class Crinja::FeatureLibrary(T)
  class UnknownFeatureException < Crinja::RuntimeError
    def initialize(kind, name)
      super "no #{kind} with name \"#{name}\" registered"
    end
  end

  property store : Hash(String, T)
  property aliasses : Hash(String, String)

  # Creates a new feature library.
  # If *register_defaults* is set to `false`, this library will be empty. Otherwise it is populated
  # with registered default features.
  def initialize(register_defaults = true)
    # FIXME: Move ivar initialization to property definition
    @store = {} of String => T
    @aliasses = {} of String => String
    self.register_defaults if register_defaults
  end

  delegate :each, :keys, to: store

  # Adds default values to this library.
  def register_defaults; end

  macro inherited
    # Create a local method in a subclass to allow the usage of `previous_def`.
    def register_defaults
      @@defaults.each do |callable|
        self << callable
      end
      @aliasses.merge! @@aliasses
    end

    class_getter defaults = [] of T

    @@aliasses = {} of String => String
    def self.alias(from, to)
      @@aliasses[from.to_s] = to.to_s
    end
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
    name = if obj.responds_to?(:name)
             obj.name
           else
             obj.class.to_s.split("::")[-1].downcase
           end

    self[name] = obj
  end

  # Retrieves the feature object in this library with key *name*.
  def [](name) : T
    lookup = name.to_s.downcase
    lookup = aliasses.fetch(lookup, lookup)
    store[lookup]
  rescue
    raise UnknownFeatureException.new(self.name, name.downcase)
  end

  # Stores a feature object *obj* under the key *name*.
  def []=(name, obj : T)
    store[name.to_s.downcase] = obj
  end

  # Stores a feature object *obj* under the key *name*.
  def []=(name, klass : Class)
    self[name] = klass.new
  end

  def has_key?(name)
    lookup = name.to_s.downcase
    lookup = aliasses.fetch(lookup, lookup)
    store.has_key?(lookup)
  end

  def inspect(io : IO)
    store.inspect(io)
  end

  def name
    {{ @type.stringify.split("::")[-2].downcase }}
  end
end
