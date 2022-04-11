abstract class Crinja::FeatureLibrary(T)
  class UnknownFeatureError < Crinja::RuntimeError
    def initialize(kind, name)
      super %(no #{kind} with name "#{name}" registered)
    end
  end

  # Map of aliases.
  getter aliases : Hash(String, String)

  # List of disabled features.
  getter disabled : Array(String)

  # Creates a new feature library.
  # If *register_defaults* is set to `false`, this library will be empty. Otherwise it is populated
  # with registered default features.
  # A list of *disabled* features can be provided, if a feature name in this list is accessed,
  # it will raise a `SecurityError`.
  def initialize(register_defaults = true, @disabled = [] of String)
    # FIXME: Move ivar initialization to property definition
    @store = {} of String => T
    @aliases = {} of String => String

    self.register_defaults if register_defaults
  end

  delegate each, keys, size, to: @store

  # Adds default values to this library.
  def register_defaults; end

  macro inherited
    # Create a local method in a subclass to allow the usage of `previous_def`.
    def register_defaults
      @@defaults.each do |callable|
        self << callable
      end
      @aliases.merge! @@aliases
    end

    class_getter defaults = [] of T

    @@aliases = {} of String => String
    def self.alias(from, to)
      @@aliases[from.to_s] = to.to_s
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
           elsif obj.class != Callable::Instance
             obj.class.to_s.split("::")[-1].downcase
           end

    raise "cannot append unnamed feature, use `#[name]=` instead" if name.nil?

    self[name] = obj
  end

  # Retrieves the feature object in this library with key or alias *lookup*.
  #
  # If the lookup name is in the list of `#disabled` features, a `SecurityError` is raised.
  # If the lookup name is not registered, an `UnknownFeatureError` is raised.
  def [](lookup) : T
    lookup = lookup.to_s.downcase
    lookup = @aliases.fetch(lookup, lookup)

    feature = @store[lookup]?

    if disabled.includes?(lookup)
      feature_name = feature.try(&.to_s) || lookup
      raise SecurityError.new("access to #{name} `#{feature_name}` is disabled.")
    end

    raise UnknownFeatureError.new(self.name, lookup) if feature.nil?

    feature
  end

  # Stores a feature object *obj* under the key *name*.
  def []=(name, obj : T)
    @store[name.to_s.downcase] = obj
  end

  # Stores a feature object *obj* under the key *name*.
  def []=(name, klass : Class)
    self[name] = klass.new
  end

  def has_key?(name)
    lookup = name.to_s.downcase
    lookup = @aliases.fetch(lookup, lookup)
    @store.has_key?(lookup)
  end

  def inspect(io : IO)
    @store.inspect(io)
  end

  def name
    {{ @type.stringify.split("::")[-2].downcase }}
  end
end
