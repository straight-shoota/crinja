# The central template object. This class represents a compiled template and is used to evaluate it.
# Normally the template object is generated from an `Environment` by `Environment#from_string` or `Environment#get_template` but it also has a constructor that makes it possible to create a template instance directly, which refers to a default environment.
# Every template object has a few methods and members that are guaranteed to exist. However it’s important that a template object should be considered immutable. Modifications on the object are not supported.
class Crinja::Template
  property macros : Hash(String, Crinja::Tag::Macro::MacroFunction) = Hash(String, Crinja::Tag::Macro::MacroFunction).new

  getter source

  # The loading name of the template. If the template was loaded from a string this is `nil`.
  getter name

  # The filename of the template on the file system if it was loaded from there. Otherwise this is `nil`.
  getter filename

  # Returns the root node of this template's abstract syntax tree.
  getter nodes : AST::NodeList

  getter env : Environment

  # Creates a new template.
  def initialize(@source : String, @env : Environment = Environment.new, @name : String = "", @filename : String? = nil)
    @source = @source.rchop '\n' unless env.config.keep_trailing_newline

    @nodes = AST::NodeList.new([] of AST::TemplateNode, false)

    begin
      @nodes = Parser::TemplateParser.new(@env, @source).parse
    rescue e : TemplateError
      e.template = self
      raise ExceptionWrapper.new(cause: e)
    end
  end

  def register_macro(name, instance)
    macros[name] = instance
    env.context.macros[name] = instance
  end

  # Renders this template as a `String` using *bindings* as local variables scope.
  def render(bindings = nil)
    String.build do |io|
      self.render(io, bindings)
    end
  end

  # Renders this template to *io* using *bindings* as local variables scope.
  def render(io : IO, bindings = nil)
    env.with_scope(bindings) do
      self.render(io, env)
    end
  end

  # Renders this template to *io* in the environment *env*.
  # This method might return unexpected results if *env* differs from the original environment this template was parsed with.
  def render(io : IO, env : Environment)
    renderer = Renderer.new(self)
    renderer.render(io, self)
  rescue e : TemplateError
    e.template = self
    raise ExceptionWrapper.new(cause: e)
  end

  # :nodoc:
  def to_s(io : IO)
    io << "Template"
    io << "("
    name.to_s(io)
    io << ")"
  end

  def to_string
    source
  end
end
