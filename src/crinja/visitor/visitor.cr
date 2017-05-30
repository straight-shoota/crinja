module Crinja
  abstract class Visitor(T)
    alias AST = Parser

    macro visit(*node_types)
      def visit(node : {{
                         (node_types.map do |type|
                           "Parser::#{type.id}"
                         end).join(" | ").id
                       }})
        {{ yield }}
      end
    end
  end
end
