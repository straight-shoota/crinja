Crinja.function(:super) do
  block_context = env.context.block_context
  unless block_context.nil?
    block_context = {name: block_context[:name], index: block_context[:index] + 1}
    block_chain = env.blocks[block_context[:name]]

    raise "cannot call super block" if block_chain.size <= block_context[:index]
    super_block = block_chain[block_context[:index]]
    arguments.env.context.block_context = block_context

    Visitor::Renderer.new(env).visit(super_block).value unless super_block.nil?
  end
end
