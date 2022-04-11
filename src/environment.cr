require "./runtime/context"
require "./config"
require "./loader"
require "./runtime/resolver"
require "log"

class Crinja
  Log = ::Log.for(self)

  # The current context in which evaluation happens. It can only be changed by `#with_context`.
  getter context : Context

  # The global context.
  getter global_context : Context

  # The configuration for this environment.
  getter config : Config

  # The logger for this environment.
  getter logger : ::Log = Log

  # The loader through which `#get_template` loads a template.
  # Defaults to `Loader::FileSystemLoader` with searchpath of the current working directory.
  property loader : Loader

  # A cache where parsed templates are stored. Defaults to `TemplateCache::InMemory`.
  property cache : TemplateCache

  property errors : Array(Exception) = [] of Exception

  # Operator library for this environment.
  #
  # See `Crinja::Operator` for a list of builtin operators.
  getter operators

  # Filter library for this environment.
  #
  # See `Crinja::Filter` for a list of builtin filters.
  getter filters

  # Function library for this environment.
  #
  # See `Crinja::Function` for a list of builtin functions.
  getter functions

  # Tag library for this environment.
  #
  # See `Crinja::Tag` for a list of builtin tags.
  getter tags

  # Test library for this environment.
  #
  # See `Crinja::Test` for a list of builtin tests.
  getter tests

  # Policies for this environment.
  getter policies = Variables.new

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
    # context["self"] = BlocksResolver.new(self)

    @operators = Operator::Library.new(config.register_defaults, config.disabled_operators)
    @functions = Function::Library.new(config.register_defaults, config.disabled_functions)
    @filters = Filter::Library.new(config.register_defaults, config.disabled_filters)
    @tags = Tag::Library.new(config.register_defaults, config.disabled_tags)
    @tests = Test::Library.new(config.register_defaults, config.disabled_tests)

    @finalizer = Finalizer
  end

  # Creates a new environment with the context and configuration from the *original* environment.
  def self.new(original : Crinja)
    new(Context.new(original.context), original.config, original.loader)
  end

  # Creates a new environment from *config*.
  def self.new(config : Config, loader = Loader::FileSystemLoader.new,
               cache = TemplateCache::InMemory.new)
    new(Context.new, config, loader, cache)
  end

  # Returns an `Crinja::Evaluator` which allows evaluation of expressions.
  def evaluator
    @evaluator ||= Evaluator.new(self)
  end

  # Evaluates a Crinja expression with `#evaluator` and returns the resulting raw value.
  def evaluate(expression : AST::ExpressionNode, bindings) : Value
    with_scope(bindings) do
      evaluate(expression)
    end
  end

  def evaluate(expression : AST::ExpressionNode) : Value
    evaluator.value(expression)
  end

  # Parses and evaluates a Crinja expression with `#evaluator`. Returns a string which will be
  # auto-escaped if `config.autoescape?` is `true`.
  def evaluate(expression, bindings = nil) : String
    lexer = Parser::ExpressionLexer.new(config, expression)
    parser = Parser::ExpressionParser.new(lexer)

    expression = parser.parse

    @context.autoescape = @config.autoescape?

    result = evaluate expression, bindings

    stringify(result)
  end

  # Loads a template from *string.* This parses the given string and returns a `Template` object.
  def from_string(string : String)
    Template.new(string, self)
  end

  # Loads a template from the loader. If a loader is configured this method ask the loader for the template and returns a `Template`.
  # If the parent parameter is not None, join_path() is called to get the real template name before loading.
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

    logger.debug { "new context #{ctx} is not the child of former context" } if ctx.parent != @context
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

  # Turns *object* into a string represenation using `Crinja::Finalizer`.
  def stringify(object, pretty = false)
    @finalizer.stringify(object, context.autoescape?)
  end

  # Creates a new `undefined`.
  def undefined(name = nil)
    Value.new Undefined.new(name)
  end

  # :nodoc:
  def inspect(io : IO)
    io << "<"
    io << "Crinja"
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
