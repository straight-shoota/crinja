require "../util/for_loop"

module Crinja
  class Tag::For < Tag
    name "for", "endfor"

    LOOP_VARIABLE = "loop"

    def validate_arguments
      validate_argument 0, klass = Statement::Name
      validate_argument 1, klass = Statement::Name, token_value = "in"
      validate_argument 2, klass = Statement
      validate_arguments_size 3
    end

    def interpret_output(env : Crinja::Environment, tag_node : Node::Tag)
      next_vararg = 0
      item_vars = [] of String
      while next_vararg < tag_node.varargs.size
        break unless (name_node = tag_node.varargs[next_vararg]).is_a?(Statement::Name)
        name = name_node.name

        next_vararg += 1
        break if name == "in"

        if name == LOOP_VARIABLE
          raise TemplateSyntaxError.new(name_node.token, "cannot use reserved name `loop` as item variable in for loop")
        end

        item_vars << name
      end

      runner = Runner.new(env, tag_node, item_vars)

      collection = env.evaluator.value(tag_node.varargs[next_vararg])
      next_vararg += 1

      if tag_node.varargs.size > next_vararg && tag_node.varargs[next_vararg].as(Statement::Name).name == "if"
        if_stmt = tag_node.varargs[next_vararg + 1].as(Statement)

        collection = ConditionalIterator.new(collection.each, if_stmt, env, item_vars)
      end

      if tag_node.varargs.size > next_vararg && (recursive = tag_node.varargs[next_vararg]).is_a?(Statement::Name) && recursive.name == "recursive"
        looper = Util::ForLoop::Recursive.new runner, collection
      else
        looper = Util::ForLoop.new collection
      end

      result = runner.run_loop(looper)

      if looper.index == 0
        # no items were processed, render else branch
        runner.render_children(true)
      else
        result
      end
    end

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
      raise "Unsupported operation"
    end

    class Runner
      getter env, tag_node, item_vars

      def initialize(@env : Crinja::Environment, @tag_node : Node::Tag, @item_vars : Array(String))
      end

      def run_loop(looper : Util::ForLoop)
        Node::OutputList.new.tap do |output|
          looper.each do |value|
            env.with_scope({LOOP_VARIABLE => looper}) do |context|
              context.unpack item_vars, value.raw
              output << render_children
            end
          end
        end
      end

      def render_children(else_branch = false) : Node::Output
        Node::OutputList.new.tap do |output|
          tag_node.children.each do |node|
            if node.is_a?(Node::Tag) && "else" == node.as(Node::Tag).name
              break unless else_branch
              else_branch = false
            end

            output << Visitor::Renderer.new(env).visit(node) unless else_branch
          end
        end
      end
    end

    class ConditionalIterator
      include Iterator(Value)
      include IteratorWrapper

      def initialize(@iterator : Iterator(Value), @condition : Statement, @env : Environment, @item_vars : Array(String))
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
end
