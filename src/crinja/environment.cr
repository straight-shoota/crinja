require "./context"
require "./config"
require "./loader"
require "./interpreter/resolver"
require "logger"

# The core component of Crinja is the `Environment`. It contains configuration, global variables and provides an API for template loading and rendering. Instances of this class may be modified if they are not shared and if no template was loaded so far. Modifications on environments after the first template was loaded will lead to surprising effects and undefined behavior.
class Crinja::Environment
  getter context : Context
  getter global_context : Context

  # The configuration for this environment.
  getter config : Config

  # The logger for this environment.
  getter logger : Logger

  # The loader through which `#get_template` loads a template.
  # Defaults to `Loader::FileSystemLoader` with searchpath of the current working directory.
  property loader : Loader

  # A cache where parsed templates are stored. Defaults to `TemplateCache::InMemory`.
  property cache : TemplateCache

  property errors : Array(Exception) = [] of Exception

  # Operator library for this environment.
  getter operators

  # Filter library for this environment.
  getter filters

  # Function library for this environment.
  getter functions

  # Tag library for this environment.
  getter tags

  # Test library for this environment.
  getter tests

  # Creates a new environment and yields `self` for configuration.
  def self.new(context = Context.new, config = Config.new,
               loader = Loader::FileSystemLoader.new, cache = TemplateCache::InMemory.new)
    env = new(context, config, loader, cache)
    yield env
    env
  end

  # Creates a new environment with default values. The *context* becomes both `#global_context`
  # as well as current ``#context`.
  def initialize(@context = Context.new, @config = Config.new,
                 @loader = Loader::FileSystemLoader.new, @cache = TemplateCache::InMemory.new)
    @global_context = @context

    @logger = Logger.new(STDOUT)
    {% if flag?(:logger) %}
      @logger.level = Logger::DEBUG
    {% end %}
    # context["self"] = BlocksResolver.new(self)

    @operators = Operator::Library.new(config.register_defaults)
    @functions = Function::Library.new(config.register_defaults)
    @filters = Filter::Library.new(config.register_defaults)
    @tags = Tag::Library.new(config.register_defaults)
    @tests = Test::Library.new(config.register_defaults)
  end

  def initialize(original : Environment)
    initialize(Context.new(original.context), original.config, original.loader)
  end

  def evaluator
    @evaluator ||= Evaluator.new(self)
  end

  # Evaluates a Crinja expression with `#evaluator`.
  def evaluate(expression : AST::ExpressionNode)
    evaluator.evaluate(expression)
  end

  # ditto
  def evaluate(expression)
    lexer = Parser::ExpressionLexer.new(config, expression)
    parser = Parser::ExpressionParser.new(lexer)

    result = evaluate parser.parse

    if config.autoescape?
      result = SafeString.escape(result)
    end

    result
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
