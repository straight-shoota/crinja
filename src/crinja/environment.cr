require "./context"
require "./config"
require "./loader"
require "logger"

class Crinja::Environment
  getter context : Context
  getter global_context : Context
  getter config : Config = Config.new
  getter logger : Logger
  property loader : Loader = Loader::FileSystemLoader.new

  def initialize(@context = Context.new)
    @global_context = @context
    @logger = Logger.new(STDOUT)
  end

  def initialize(origial : Environment)
    initialize(Context.new(origial.context))
  end

  def from_string(string : String)
    Template.new(self, string)
  end

  def load(name)
    loader.load(self, name)
  end

  def with_scope(ctx : Context)
    former_scope = self.context
    @context = ctx

    result = yield @context
  ensure
    @context = former_scope.not_nil!

    result
  end

  def with_scope(bindings = nil)
    ctx = Context.new(self.context)

    unless bindings.nil?
      ctx.merge! Crinja::Bindings.cast(bindings)
    end

    with_scope(ctx) do |c|
      yield c
    end
  end

  def inspect(io : IO)
    io << "<"
    io << "Crinja::Environment"
    io << " @context="
    context.inspect(io)
    io << ">"
  end

  def resolve(name : String)
    logger.debug "resolving string #{name} in context"
    context[name]
  end

  def resolve(variable : Variable)
    logger.debug "resolving variable #{variable}"
    value = context
    variable.parts.each do |part|
      if value.responds_to?(:getattr)
        value = value.getattr(part)
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
    value.as(Type)
  end
end
