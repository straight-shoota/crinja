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
  property extend_parent_templates : Array(Template) = [] of Template
  property errors : Array(Exception) = [] of Exception

  property blocks : Hash(String, Array(Array(Node)))
  @blocks = Hash(String, Array(Array(Node))).new do |hash, k|
    hash[k] = Array(Array(Node)).new
  end

  def initialize(@context = Context.new)
    @global_context = @context
    @logger = Logger.new(STDOUT)
    # context["self"] = BlocksResolver.new(self)
  end

  def initialize(original : Environment)
    initialize(Context.new(original.context))
  end

  def from_string(string : String)
    Template.new(string, self)
  end

  def get_template(name, parent = nil, globals = Hash(String, Type).new)
    template = loader.load(self, name)
    template.globals = globals
    template
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

    if value.is_a?(Any)
      value = value.raw
    end

    value.as(Type)
  end

  def resolve_with_hash_accessor(name, object)
    if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(Tuple)
      begin
        return object[name]
      rescue KeyError
      end
    end

    Undefined.new(name)
  end

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

    if value.is_a?(Any)
      value = value.raw
    end

    value.as(Type)
  end

  def resolve(name : String)
    logger.debug "resolving string #{name} in context"
    context[name]
  end

  def resolve(variable : Variable)
    logger.debug "resolving variable #{variable}"
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
