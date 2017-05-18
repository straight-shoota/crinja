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
  # A `Hash` with the globals of that template. It’s unsafe to modify this dict as it may be shared with other templates or the environment that loaded the template.
  getter globals : Hash(String, Type)
  getter env : Environment

  # Creates a new template.
  def initialize(@source : String, e : Environment = Environment.new, @name : String = "", @filename : String? = nil, globals = nil)
    # duplicate environment for this template to avoid spilling to global scope, but keep current scope
    # even if render method has finished
    @env = e.dup

    @source = @source.rchop '\n' unless env.config.keep_trailing_newline
    @globals = globals.nil? ? Hash(String, Type).new : globals

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
      render(io, bindings)
    end
  end

  # Renders this template to *io* using *bindings* as local variables scope.
  def render(io : IO, bindings = nil)
    env.with_scope(globals) do
      env.with_scope(bindings) do
        render(io, env)
      end
    end
  end

  # Renders this template to *io* in the environment *env*.
  # This method might return unexpected results if *env* differs from the original environment this template was parsed with.
  def render(io : IO, env : Environment)
    env.context.autoescape = env.config.autoescape?(filename)

    env.context.macros.merge(self.macros)
    output = render_nodes(env, root.children)

    env.extend_parent_templates.each do |parent_template|
      output = render_nodes(env, parent_template.root.children)

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

  private def render_nodes(env, nodes)
    Node::OutputList.new.tap do |output|
      nodes.each do |node|
        output << node.render(env)
      end
    end
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

            output = render_nodes(env, block)

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
      root.accept Crinja::SourceVisitor.new(io)
    end
  end
end
