require "./parser"

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

  getter env : Environment

  # Creates a new template.
  def initialize(@source : String, @env : Environment = Environment.new, @name : String = "", @filename : String? = nil)
    @source = @source.rchop '\n' unless env.config.keep_trailing_newline

    @root = Node::Root.new(self)
    Parser::TemplateParser.new(self, root).build
  end

  # Returns the root node of this template's abstract syntax tree.
  def root
    @root.not_nil!
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
    #env.with_scope(globals) do
      env.with_scope(bindings) do
        self.render(io, env)
      end
    #end
  end

  # Renders this template to *io* in the environment *env*.
  # This method might return unexpected results if *env* differs from the original environment this template was parsed with.
  def render(io : IO, env : Environment)
    env.context.autoescape = env.config.autoescape?(filename)

    env.context.macros.merge(self.macros)
    renderer = Visitor::Renderer.new(env)
    output = renderer.visit(root)

    env.extend_parent_templates.each do |parent_template|
      output = renderer.visit(parent_template.root)

      env.context.extend_path_stack.pop
    end

    resolve_block_stubs(env, output)

    output.value(io)
  end

  # :nodoc:
  def to_s(io : IO)
    io << "Template"
    io << "("
    name.to_s(io)
    io << ")"
  end

  private def resolve_block_stubs(env, output, block_names = Array(String).new)
    output.each_block do |placeholder|
      name = placeholder.name
      unless block_names.includes?(name)
        block_chain = env.blocks[name]

        if block_chain.size > 0
          block = block_chain.first

          scope = env.context
          unless (original_scope = placeholder.scope).nil?
            scope = original_scope
          end

          env.with_scope(scope) do
            env.context.block_context = {name: name, index: 0}

            output = Visitor::Renderer.new(env).visit(block)

            block_names << name
            resolve_block_stubs(env, output, block_names)

            block_names.pop

            env.context.block_context = nil
          end

          placeholder.resolve(output.value)
        end
      end

      placeholder.resolve("") unless placeholder.resolved?
    end
  end

  def to_string
    String.build do |io|
      root.accept Crinja::Visitor::Source.new(io)
    end
  end
end
