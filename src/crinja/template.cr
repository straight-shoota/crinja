require "./parser"

class Crinja::Template
  property macros : Hash(String, Crinja::Tag::Macro::MacroInstance) = Hash(String, Crinja::Tag::Macro::MacroInstance).new
  getter string, name, filename
  property globals : Hash(String, Type)
  getter env : Environment

  def initialize(@string : String, e : Environment = Environment.new, @name : String = "", @filename : String? = nil)
    # duplicate environment for this template to avoid spilling to global scope, but keep current scope
    # even if render method has finished
    @env = e.dup

    @string = @string.rchop '\n' unless env.config.keep_trailing_newline
    @globals = Hash(String, Type).new

    @root = Node::Root.new(self)
    Parser::TemplateParser.new(self, root).build
  end

  def root
    @root.not_nil!
  end

  def register_macro(name, instance)
    macros[name] = instance
    env.context.macros[name] = instance
  end

  def render(bindings = nil)
    String.build do |io|
      render(io, bindings)
    end
  end

  def render(io : IO, bindings = nil)
    env.with_scope(globals) do
      env.with_scope(bindings) do
        render(io, env)
      end
    end
  end

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
end
