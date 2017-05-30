require "../util/for_loop"

class Crinja::Tag::For < Crinja::Tag
  name "for", "endfor"

  LOOP_VARIABLE = "loop"

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments)
    item_vars, collection_expr, if_expr, recursive = parser.parse_for_tag

    runner = Runner.new(renderer, tag_node, item_vars)

    collection = env.evaluator.value(collection_expr)

    if if_expr
      collection = ConditionalIterator.new(collection.each, if_expr, env, item_vars)
    end

    if recursive
      looper = Util::ForLoop::Recursive.new runner, collection
    else
      looper = Util::ForLoop.new collection
    end

    result = runner.run_loop(looper)

    if looper.index == 0
      # no items were processed, render else branch
      runner.render_else
    else
      result
    end
  end

  class Parser < ArgumentsParser
    def parse_for_tag
      item_vars = parse_identifier_list.map do |identifier|
        if identifier.name == LOOP_VARIABLE
          raise TemplateSyntaxError.new(identifier, "cannot use reserved name `loop` as item variable in for loop")
        end
        identifier.name
      end

      expect Kind::IDENTIFIER, "in"

      collection_expr = parse_expression

      if_expr : AST::ExpressionNode? = nil
      if_token Kind::IDENTIFIER, "if" do
        next_token
        if_expr = parse_expression
      end

      recursive = false
      if_token Kind::IDENTIFIER, "recursive" do
        recursive = true
      end

      close

      return {item_vars, collection_expr, if_expr, recursive}
    end
  end

  class Runner
    def initialize(@renderer : Renderer, @tag_node : TagNode, @item_vars : Array(String))
    end

    def run_loop(looper : Util::ForLoop)
      Renderer::OutputList.new.tap do |output|
        looper.each do |value|
          @renderer.env.with_scope({LOOP_VARIABLE => looper}) do |context|
            context.unpack @item_vars, value.raw
            output << render_children
          end
        end
      end
    end

    def render_else
      render_children(true)
    end

    def render_children(else_branch = false)
      Renderer::OutputList.new.tap do |output|
        @tag_node.block.children.each do |node|
          if node.is_a?(TagNode) && "else" == node.name
            break unless else_branch
            else_branch = false
          end

          output << @renderer.render(node) unless else_branch
        end
      end
    end
  end

  class ConditionalIterator
    include Iterator(Value)
    include IteratorWrapper

    def initialize(@iterator : Iterator(Value), @condition : AST::ExpressionNode, @env : Environment, @item_vars : Array(String))
    end

    def next
      loop do
        value = wrapped_next
        @env.context[LOOP_VARIABLE] = StrictUndefined.new(LOOP_VARIABLE)
        @env.context.unpack(@item_vars, value.raw)

        if @env.evaluator.value(@condition).truthy?
          return value
        end
      end
    end
  end
end
