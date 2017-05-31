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

  class Parser < ArgumentsParser
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
