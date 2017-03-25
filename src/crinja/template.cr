require "./parser"

class Crinja::Template
  property macros : Hash(String, Crinja::Tag::Macro::MacroInstance) = Hash(String, Crinja::Tag::Macro::MacroInstance).new
  getter string, name
  getter env : Environment

  def initialize(e : Environment, @string : String, @name : String = "")
    # duplicate environment for this template to avoid spilling to global scope, but keep current scope
    # even if render method has finished
    @env = e.dup
    @root = Node::Root.new(self)
    Parser::TemplateParser.new(self, root).build
  end

  def root
    @root.not_nil!
  end

  def render(bindings = nil)
    String.build do |io|
      render(io, bindings)
    end
  end

  def render(io : IO, bindings = nil)
    env.with_scope(bindings) do
      render(io, env)
    end
  end

  def render(io : IO, env : Environment)
    output = render_nodes(env, root.children)

    env.extend_parent_templates.each do |parent_template|
      output = render_nodes(env, parent_template.root.children)

      env.context.parent_templates.pop
    end

    resolve_block_stubs(env, output)

    output.value(io)
  end

  private def render_nodes(env, nodes)
    Node::OutputList.new.tap do |output|
      nodes.each do |node|
        output << node.render(env)
      end
    end
  end

  private def resolve_block_stubs(env, output, block_names = Array(String).new)
    output.blocks.each do |placeholder|
      name = placeholder.name
      unless block_names.includes?(name)
        block_chain = env.blocks[name]

        if block_chain.size > 0
          block = block_chain[0]
          super_block = block_chain[1] if block_chain.size > 1
          env.context.super_block = super_block

          output = render_nodes(env, block)
          block_names << name
          resolve_block_stubs(env, output, block_names)
          block_names.pop

          env.context.super_block = nil
          placeholder.resolve(output.value)
        end
      end

      placeholder.resolve("") unless placeholder.resolved?
    end
  end
end
