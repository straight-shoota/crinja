require "./context"
require "./config"
require "./loader"
require "logger"

# The core component of Crinja is the `Environment`. It contains configuration, global variables and provides an API for template loading and rendering. Instances of this class may be modified if they are not shared and if no template was loaded so far. Modifications on environments after the first template was loaded will lead to surprising effects and undefined behavior.
class Crinja::Environment
  getter context : Context
  getter global_context : Context
  getter config : Config = Config.new
  getter logger : Logger
  property loader : Loader = Loader::FileSystemLoader.new
  property extend_parent_templates : Array(Template) = [] of Template
  property errors : Array(Exception) = [] of Exception

  property blocks : Hash(String, Array(Array(Node)))
  @blocks = Hash(String, Array(Array(Node))).new do |hash, k|
    hash[k] = Array(Array(Node)).new
  end

  def initialize(@context = Context.new)
    @global_context = @context
    @logger = Logger.new(STDOUT)
    {% if flag?(:debug) %}
      @logger.level = Logger::DEBUG
    {% end %}
    # context["self"] = BlocksResolver.new(self)
  end

  def initialize(original : Environment)
    initialize(Context.new(original.context))
  end

  # Loads a template from *string.* This parses the source given and returns a `Template` object.
  def from_string(string : String)
    Template.new(string, self)
  end

  # Loads a template from the loader. If a loader is configured this method ask the loader for the template and returns a `Template`.
  # *If the parent parameter is not None, join_path() is called to get the real template name before loading.
  # TODO: *parent* parameter is not implemented.
  # The *globals* parameter can be used to provide template wide globals. These variables are available in the context at render time.
  # If the template does not exist a `TemplateNotFoundError` is raised.
  # TODO: Cache template parsing
  def get_template(name : String, parent = nil, globals = nil)
    string, file_name = loader.get_source(self, name)
    Template.new(string, self, name, file_name)
  end

  # Works like `#get_template(String)` but tries a number of templates before it fails. If it cannot find any of the templates, it will raise a `TemplateNotFoundError`.
  def get_template(names : Iterable(String), parent = nil, globals = nil)
    names.each do |name|
      begin
        return get_template(name)
      rescue TemplateNotFoundError
      end
    end

    raise TemplateNotFoundError.new(names, self)
  end

  # Alias for `#get_template(Iterable(String))`.
  def select_template(names, parent = nil, globals = nil)
    get_template(names, parent, globals)
  end

  # Executes the block inside the context `ctx` and returns to the previous context afterwards.
  def with_scope(ctx : Context)
    former_scope = self.context
    @context = ctx

    result = yield @context
  ensure
    @context = former_scope.not_nil!

    result
  end

  # Executes the block inside a new sub-context with optional local scoped *bindings*.
  # Returns to the previous context afterwards.
  def with_scope(bindings = nil)
    ctx = Context.new(self.context)

    unless bindings.nil?
      ctx.merge! Crinja::Bindings.cast(bindings)
    end

    with_scope(ctx) do |c|
      yield c
    end
  end

  def undefined
    Value.undefined
  end

  # :nodoc:
  def inspect(io : IO)
    io << "<"
    io << "Crinja::Environment"
    io << " @context="
    context.inspect(io)
    io << ">"
  end

  # Resolves an objects item.
  # Analogous to `__getitem__` in Jinja2.
  def resolve_item(name : String, object)
    value = Undefined.new(name)
    if object.responds_to?(:getitem)
      value = object.getitem(name)
    end
    if value.is_a?(Undefined) && object.responds_to?(:getattr)
      value = object.getattr(name)
    end
    if value.is_a?(Undefined)
      value = resolve_with_hash_accessor(name, object)
    end

    if value.is_a?(Value)
      value = value.raw
    end

    value.as(Type)
  end

  private def resolve_with_hash_accessor(name, object)
    if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(Tuple)
      begin
        return object[name]
      rescue KeyError
      end
    end

    Undefined.new(name)
  end

  # Resolves an objects attribute.
  # Analogous to `getattr` in Jinja2.
  def resolve_attribute(name : String, object)
    value = Undefined.new(name)
    if object.responds_to?(:getattr)
      value = object.getattr(name)
    end
    if value.is_a?(Undefined) && object.responds_to?(:getitem)
      value = object.getitem(name)
    end
    if value.is_a?(Undefined)
      value = resolve_with_hash_accessor(name, object)
    end

    if value.is_a?(Value)
      value = value.raw
    end

    value.as(Type)
  end

  # Resolves a variable in the current context.
  def resolve(name : String)
    value = context[name]
    logger.debug "resolved string #{name}: #{value.inspect}"
    value
  end

  # Resolves a variable in the current context.
  def resolve(variable : Variable)
    logger.debug "resolving variable #{variable}..."
    value = context
    variable.parts.each do |part|
      if !(attr = resolve_attribute(part, value)).is_a?(Undefined)
        value = attr
      elsif value.responds_to?(:[]) && value.responds_to?(:has_key?) && !value.is_a?(Array) && !value.is_a?(Tuple)
        if value.has_key?(part)
          value = value[part]
        else
          value = Undefined.new(variable.to_s)
        end
      else
        break
      end
    end
    logger.debug "resolved variable #{variable}: #{value.inspect}"
    value.as(Type)
  end

  # class BlocksResolver
  #   include PyWrapper

  #   def initialize(@env : Environment)
  #   end

  #   def getattr(attr : Type) : Type
  #     block_chain = @env.blocks[attr.to_s]
  #     if block_chain
  #       CallableBlock.new(block_chain[0])
  #     else
  #       Undefined.new(attr)
  #     end
  #   end
  # end

  # class CallableBlock
  #   include Callable

  #   def initialize(@nodes : Array(Node))
  #   end

  #   def call(arguments : Arguments)
  #     SafeString.build do |io|
  #       @nodes.each do |node|
  #         io << node.render(arguments.env).value
  #       end
  #     end
  #   end

  # end
end
