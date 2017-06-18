# Blocks are used for inheritance and act as both placeholders and replacements at the same time.
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#template-inheritance) for details.
class Crinja::Tag::Block < Crinja::Tag
  name "block", "endblock"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments)
    name, scoped = parser.parse_block_tag

    renderer.blocks[name] << tag_node.block

    block = Renderer::BlockOutput.new(name)
    block.scope = env.context if scoped

    block
  end

  private class Parser < ArgumentsParser
    def parse_block_tag
      name = parse_identifier.name

      scoped = false
      if_identifier "scoped" do
        scoped = true
      end

      close

      {name, scoped}
    end
  end
end
