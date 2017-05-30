class Crinja::Renderer
  getter env, template

  def initialize(@env : Environment, @template : Template)
  end

  macro visit(*node_types)
    def render(node : {{
                        (node_types.map do |type|
                          "Parser::#{type.id}"
                        end).join(" | ").id
                      }})
      {{ yield }}
    end
  end

  visit NodeList do
    self.render(node.children)
  end

  def render(nodes : Array(Parser::TemplateNode))
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
    trim_blocks = @env.config.trim_blocks
    lstrip_blocks = @env.config.lstrip_blocks

    RenderedOutput.new Crinja::Renderer.trim_text(node, @env.config.trim_blocks, @env.config.lstrip_blocks)
  end

  visit TagNode do
    @env.tags[node.name].interpret_output(self, node)
  end

  visit EndTagNode do
    RenderedOutput.new ""
  end

  visit Note do
    RenderedOutput.new ""
  end

  visit PrintStatement do
    result = @env.evaluate(node.expression)

    if @env.context.autoescape?
      result = SafeString.escape(result)
    end

    RenderedOutput.new result.to_s
  end

  def render(template : Template)
    String.build do |io|
      render(io, template)
    end
  end

  def render(io : IO, template : Template)
    @env.context.autoescape = @env.config.autoescape?(template.filename)

    @env.context.macros.merge(template.macros)
    output = render(template.nodes)

    @env.extend_parent_templates.each do |parent_template|
      output = render(parent_template.nodes)

      @env.context.extend_path_stack.pop
    end

    resolve_block_stubs(output)

    output.value(io)
  end

  private def resolve_block_stubs(output, block_names = Array(String).new)
    output.each_block do |placeholder|
      name = placeholder.name
      unless block_names.includes?(name)
        block_chain = @env.blocks[name]

        if block_chain.size > 0
          block = block_chain.first

          scope = @env.context
          unless (original_scope = placeholder.scope).nil?
            scope = original_scope
          end

          @env.with_scope(scope) do
            @env.context.block_context = {name: name, index: 0}

            output = render(block)

            block_names << name
            resolve_block_stubs(output, block_names)

            block_names.pop

            @env.context.block_context = nil
          end

          placeholder.resolve(output.value)
        end
      end

      placeholder.resolve("") unless placeholder.resolved?
    end
  end
end
