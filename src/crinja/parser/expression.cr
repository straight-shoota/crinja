module Crinja::Parser
  module BuildExpression
    def build_expression_node(token)
      node = Node::Expression.new(token)

      root = Statement::Root.new(token)
      root.parent_node = node
      statement_parser = StatementParser.new(self, root)
      statement_parser.expected_end_token = Kind::EXPR_END
      statement = statement_parser.build
      node.end_token = current_token

      unless statement.nil?
        node.statement = statement
      else
        raise "Empty statement"
      end

      node.parent = @parent.as(Node)

      node
    end
  end
end
