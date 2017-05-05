module Crinja
  class Function::Super < Function
    name "super"

    def call(arguments : Arguments) : Type
      env = arguments.env

      block_context = arguments.env.context.block_context
      unless block_context.nil?
        block_context = {name: block_context[:name], index: block_context[:index] + 1}
        block_chain = env.blocks[block_context[:name]]

        raise "cannot call super block" if block_chain.size <= block_context[:index]
        super_block = block_chain[block_context[:index]]
        arguments.env.context.block_context = block_context

        SafeString.build do |io|
          super_block.each do |node|
            io << node.render(env).value
          end
        end unless super_block.nil?
      end
    end
  end
end
