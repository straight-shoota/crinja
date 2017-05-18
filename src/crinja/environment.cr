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
  property cache : TemplateCache = TemplateCache::InMemory.new

  getter operators, filters, functions, tags, tests

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

    @operators = Operator::Library.new
    @functions = Function::Library.new
    @filters = Filter::Library.new
    @tags = Tag::Library.new
    @tests = Test::Library.new
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
    loader.load(self, name)
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

    logger.info "new context #{ctx} is not the child of former context" if ctx.parent != @context
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
    io << " @libraries="
    {% for library in ["operators", "functions", "filters", "tags"] %}
    io << " " << {{ library.id.stringify }} << "=["
    {{ library.id }}.keys.each do |item|
      io << item << ", "
    end
    io << "]"
    {% end %}
    # io << " @context="
    # context.inspect(io)
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
    variable.parts.each_with_index do |part, index|
      if index == 0 && functions.has_key?(variable.to_s)
        # There might be a global function with this name.
        # Global functions can have dots in their name, so we need to check all parts of the variable.
        value = functions[variable.to_s]
        logger.debug "found function: #{variable.to_s}: #{value}"
        break
      end

      if !(attr = resolve_attribute(part, value)).is_a?(Undefined)
        value = attr
      elsif value.responds_to?(:[]) && value.responds_to?(:has_key?) && !value.is_a?(Array) && !value.is_a?(Tuple)
        if value.has_key?(part)
          value = value[part]
        else
          value = Undefined.new(variable.to_s)
          break
        end
      else
        logger.debug "could not resolve part of variable #{variable.to_s}: #{part} (#{index})"
        break
      end
    end

    logger.debug "resolved variable #{variable}: #{value.inspect}"
    value.as(Type)
  end

  def execute_call(target)
    if target.is_a?(Variable)
      puts target.to_s
      puts "xecuting call with context macros: #{context.all_macros.keys}"
      if context.has_macro?(target.to_s)
        # its a macro call
        callable = context.macro(target.to_s)
        puts "its a macro #{callable.inspect}"
      else
        callable = resolve(target)
        puts "resolved to #{callable}"
      end
    elsif target.callable?
      callable = target.raw
    end

    if callable.is_a?(Callable)
      arguments = Arguments.new(self)

      # if callable.is_a?(Tag::Macro::MacroFunction)
      #  ctx = Context.new
      #  context.all_macros.each do |_,makro|
      #    ctx.register_macro(makro)
      #  end
      # else
      #  ctx = self.context
      # end

      # with_scope(ctx) do
      yield(arguments)

      callable.as(Callable).call(arguments)
      # end
    else
      raise TypeError.new("cannot call #{target.inspect}. Not a callable")
    end
  end
end
