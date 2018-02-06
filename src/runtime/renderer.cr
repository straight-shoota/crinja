# The renderer traverses through an abstract syntax tree to render all template nodes to a string or IO.
class Crinja::Renderer
  getter template

  # :nodoc:
  property extend_parent_templates : Array(Template) = [] of Template

  # :nodoc:
  property blocks : Hash(String, Array(AST::NodeList))
  @blocks = Hash(String, Array(AST::NodeList)).new do |hash, k|
    hash[k] = Array(AST::NodeList).new
  end

  # Returns the environment.
  getter env : Crinja

  # Creates a new evaluator for the template *template* with optional environment *env*. If no
  # environment is provided, the environment of the template is used.
  def initialize(@template : Template, env : Crinja? = nil)
    @env = env || @template.env
  end

  private macro visit(*node_types)
    # :nodoc:
    def render(node : {{
                        (node_types.map do |type|
                          "AST::#{type.id}"
                        end).join(" | ").id
                      }})
      {{ yield }}
    rescue exc : Crinja::Error
      # Add location info to runtime exception.
      exc.at(node) unless exc.has_location?
      raise exc
    end
  end

  def render(template : Template)
    String.build do |io|
      render(io, template)
    end
  end

  def render(io : IO, template : Template)
    env.context.autoescape = env.config.autoescape?(template.filename)

    env.context.macros.merge(template.macros)
    output = render(template.nodes)

    @extend_parent_templates.each do |parent_template|
      output = render(parent_template.nodes)

      env.context.extend_path_stack.pop
    end

    resolve_block_stubs(output)

    output.value(io)
  end

  visit NodeList do
    self.render(node.children)
  end

  def render(nodes : Array(AST::TemplateNode))
    OutputList.new.tap do |output|
      nodes.each do |node|
        output << self.render(node)
      end
    end
  end

  def self.trim_text(node, trim_blocks = false, lstrip_blocks = false)
    Crinja::Util::StringTrimmer.trim(
      node.string,
      node.trim_left || (trim_blocks && node.left_is_block),
      node.trim_right || (lstrip_blocks && node.right_is_block),
      node.left_is_block,
      node.right_is_block && lstrip_blocks
    )
  end

  visit FixedString do
    trim_blocks = env.config.trim_blocks
    lstrip_blocks = env.config.lstrip_blocks

    RenderedOutput.new Crinja::Renderer.trim_text(node, env.config.trim_blocks, env.config.lstrip_blocks)
  end

  visit TagNode do
    env.tags[node.name].interpret_output(self, node)
  end

  visit EndTagNode do
    RenderedOutput.new ""
  end

  visit Note do
    RenderedOutput.new ""
  end

  visit PrintStatement do
    expr = node.expression
    if expr.is_a?(AST::CallExpression) &&
       (id = expr.identifier) && id.is_a?(AST::IdentifierLiteral) &&
       (id.as(AST::IdentifierLiteral)).name == "super"
      return render_super(expr.as(AST::CallExpression))
    end

    result = env.evaluate(expr)

    RenderedOutput.new env.stringify(result)
  end

  # global function `super` needs access to this renderer and thus needs to be implemented
  # as a language feature.
  private def render_super(expression)
    block_context = env.context.block_context

    unless block_context.nil?
      block_context = {name: block_context[:name], index: block_context[:index] + 1}
      block_chain = @blocks[block_context[:name]]

      if block_chain.size <= block_context[:index]
        raise RuntimeError.new("cannot call super block").at(expression)
      end

      super_block = block_chain[block_context[:index]]
      env.context.block_context = block_context

      self.render(super_block)
    else
      RenderedOutput.new("")
    end
  end

  private def resolve_block_stubs(output, block_names = Array(String).new)
    output.each_block do |placeholder|
      name = placeholder.name
      unless block_names.includes?(name)
        block_chain = @blocks[name]

        if block_chain.size > 0
          block = block_chain.first

          scope = env.context
          unless (original_scope = placeholder.scope).nil?
            scope = original_scope
          end

          env.with_scope(scope) do
            env.context.block_context = {name: name, index: 0}

            output = render(block)

            block_names << name
            resolve_block_stubs(output, block_names)

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
