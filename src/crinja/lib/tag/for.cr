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

    def interpret(io : IO, env : Crinja::Environment, tag_node : Node::Tag)
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

      collection = tag_node.varargs[next_vararg].value(env)
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

      runner.run_loop(io, looper)

      if looper.index == 0
        # no items were processed, render else branch
        runner.render_children(io, true)
      end
    end

    class Runner
      getter env, tag_node, item_vars

      def initialize(@env : Crinja::Environment, @tag_node : Node::Tag, @item_vars : Array(String))
      end

      def run_loop(io : IO, looper : Util::ForLoop)
        looper.each do |value|
          env.with_scope({LOOP_VARIABLE => looper}) do |context|
            context.unpack item_vars, value.raw
            render_children(io)
          end
        end
      end

      def render_children(io : IO, else_branch = false)
        tag_node.children.each do |node|
          if node.is_a?(Node::Tag) && "else" == node.as(Node::Tag).name
            return unless else_branch
            else_branch = false
          end

          node.render(io, env) unless else_branch
        end
      end
    end

    class ConditionalIterator
      include Iterator(Any)
      include IteratorWrapper

      def initialize(@iterator : Iterator(Any), @condition : Statement, @env : Environment, @item_vars : Array(String))
      end

      def next
        loop do
          value = wrapped_next
          @env.context[LOOP_VARIABLE] = StrictUndefined.new(LOOP_VARIABLE)
          @env.context.unpack(@item_vars, value.raw)

          if @condition.value(@env).truthy?
            return value
          end
        end
      end
    end
  end
end
