require "./context"
require "./config"
require "./loader"
require "./interpreter/resolver"
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

  property blocks : Hash(String, Array(Parser::NodeList))
  @blocks = Hash(String, Array(Parser::NodeList)).new do |hash, k|
    hash[k] = Array(Parser::NodeList).new
  end

  def initialize(context = Context.new)
    initialize(context)

    yield self
  end

  def initialize(@context = Context.new)
    @global_context = @context
    @logger = Logger.new(STDOUT)
    {% if flag?(:logger) %}
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

  def evaluator
    @evaluator ||= Evaluator.new(self)
  end

  delegate evaluate, to: evaluator

  # Loads a template from *string.* This parses the source given and returns a `Template` object.
  def from_string(string : String)
    Template.new(string, self)
  end

  # Loads a template from the loader. If a loader is configured this method ask the loader for the template and returns a `Template`.
  # *If the parent parameter is not None, join_path() is called to get the real template name before loading.
  # TODO: *parent* parameter is not implemented.
  # The *globals* parameter can be used to provide template wide globals. These variables are available in the context at render time.
  # If the template does not exist a `TemplateNotFoundError` is raised.
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

    logger.debug "new context #{ctx} is not the child of former context" if ctx.parent != @context
    @context = ctx

    yield @context
  ensure
    @context = former_scope.not_nil!
  end

  # Executes the block inside a new sub-context with optional local scoped *bindings*.
  # Returns to the previous context afterwards.
  def with_scope(bindings = nil)
    ctx = Context.new(self.context)

    unless bindings.nil?
      ctx.merge! bindings
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

  include Crinja::Resolver
end
