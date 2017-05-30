abstract class Crinja::Visitor(T)
  # :nodoc:
  alias AST = Crinja::Parser

  macro visit(*node_types)
    def visit(node : {{
                       (node_types.map do |type|
                         "AST::#{type.id}"
                       end).join(" | ").id
                     }})
      {{ yield }}
    end
  end
end
