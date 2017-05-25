require "logger"

module Crinja::Parser
  class StatementParser < Base
    property root_statement : Statement::Root
    property expected_end_token : Kind = Kind::EOF
    property parse_multiple : Bool = false
    property logger : Logger

    @stack : Array(Statement::ParentStatement)

    getter current_statement : Statement?
    getter env : Crinja::Environment

    def initialize(env, parser : Base, root_token : Token)
      initialize(env, parser, Statement::Root.new(root_token))
    end

    def initialize(parser : Parser::TemplateParser, root_statement : Statement = Statement::Root.new)
      initialize(parser.template.env, parser.token_stream, root_statement)
    end

    def initialize(env, lexer : Lexer::Base, root_statement = Statement::Root.new)
      initialize(env, TokenStream.new(lexer), root_statement)
    end

    def initialize(@env, @token_stream : TokenStream, @root_statement : Statement = Statement::Root.new)
      @logger = @env.logger

      @current_statement = nil
      @stack = [root_statement] of Statement::ParentStatement
    end

    def current_container
      @stack.last
    end

    def current_statement=(new_statement : Statement?)
      # if the previous statement is a function call without parenthesis, *new_statement* is to be considered an argument
      # of that function.
      if (func = current_statement).is_a?(Statement::ArgumentsList) && !func.has_parenthesis
        func.has_parenthesis = true
        @current_statement = nil
        push_stack func
      elsif !current_statement.nil?
        current_container << current_statement!
      end

      @current_statement = new_statement
    end

    def current_statement!
      stmt = current_statement

      if stmt.nil?
        raise "current_statement is nil"
      else
        stmt
      end
    end

    def push_stack(new_parent : Statement::ParentStatement)
      unless current_statement.nil?
        if current_container.is_a?(Statement::MultiRoot)
          self.current_statement = nil
        elsif (func = current_statement).is_a?(Statement::ArgumentsList) && !func.has_parenthesis
          func.has_parenthesis = true
          @stack << func
        else
          raise "current_statement is not nil: #{current_statement.inspect} new_parent=#{new_parent.inspect}"
        end
      end

      @stack << new_parent

      @current_statement = nil
    end

    def pop_stack(expected_parent = nil)
      parent = current_container

      unless expected_parent.nil? || expected_parent === parent
        raise "expected parent #{expected_parent}, but got #{current_container.inspect}"
      end

      unless current_statement.nil?
        parent << current_statement!
      end

      @current_statement = nil
      @stack.pop

      self.current_statement = parent.as(Statement)
    end

    def pop_stack?(expected_parent)
      pop_stack if current_container.class == expected_parent
    end

    def finish_current_statement
      self.current_statement = nil
    end

    def remove_current_statement!
      statement = current_statement!
      @current_statement = nil
      statement
    end

    def build : Statement
      while token = next_token?
        case token.kind
        when expected_end_token
          break
        when Kind::NAME
          name = token.value

          if env.operators.has_key?(name)
            # some operators ("not") are character sequences that seem like names to the lexer
            build_operator_node(token)
          elsif env.functions.has_key?(name)
            build_global_function_node(token)
          else
            build_variable_node(token)
          end
        when Kind::FLOAT, Kind::INTEGER, Kind::STRING, Kind::BOOL, Kind::NONE
          self.current_statement = Statement::Literal.new(token)
        when Kind::PIPE
          build_filter_node(token)
        when Kind::TEST
          build_test_node(token)
        when Kind::OPERATOR
          build_operator_node(token)
        when Kind::LIST_START
          if current_statement.nil? || token.whitespace_before
            # begin a list if there is no base object or a whitespace before opening bracket `[`
            push_stack Statement::List.new(token)
          else
            # attribute accessor
            build_attribute_operator(token)
          end
        when Kind::DICT_START
          push_stack Statement::Dict.new(token)
        when Kind::DICT_ASSIGN
          if current_container.is_a?(Statement::Dict)
            entry = Statement::Dict::Entry.new current_statement!
            @current_statement = nil
            push_stack entry
          else
            raise "Found dict assign outside of dict"
          end
        when Kind::LIST_SEPARATOR
          parent = self.current_container
          if parent.is_a?(Statement::List) || parent.is_a?(Statement::Dict) || parent.is_a?(Statement::ArgumentsList) || parent.is_a?(Statement::Tuple)
            finish_current_statement
          elsif parent.is_a?(Statement::Dict::Entry)
            pop_stack Statement::Dict::Entry
          else
            raise "Found list separator outside of list or dict parent=#{parent.inspect} statement=#{current_statement.inspect}"
          end
        when Kind::LIST_END
          pop_stack Statement::List | Statement::Attribute
        when Kind::DICT_END
          if current_container.is_a?(Statement::Dict::Entry)
            pop_stack Statement::Dict::Entry
          end
          pop_stack Statement::Dict
        when Kind::KW_ASSIGN
          raise "unsupported token #{current_token} outside of an arguments list" unless current_container.is_a?(Statement::ArgumentsList)
          raise "unsupported statement #{current_statement} as keyword" unless current_statement.is_a?(Statement::Name)
          current_container.as(Statement::ArgumentsList).await_keyword_argument(remove_current_statement!.token.value)
        when Kind::PARENTHESIS_START
          build_local_call_node(token)
        when Kind::PARENTHESIS_END
          if current_container.is_a?(Statement::SplashOperator)
            # TODO splash operator should auto-pop once it has received an operand. Same goes for
            # normal operators.
            pop_stack Statement::SplashOperator
          end
          pop_stack?(Statement::Operator) || pop_stack?(Statement::Subexpression) || pop_stack(Statement::ArgumentsList)
        when Kind::TUPLE_START
          push_stack Statement::Tuple.new(token)
        when Kind::TUPLE_END
          pop_stack Statement::Tuple
        else
          raise "Unsupported statement token #{current_token}"
        end
      end

      if current_statement.nil?
        # empty statement, might be valid tag without arguments
        # raise "current_statement is nil"
      else
        self.current_statement = nil
      end

      while @stack.size > 1
        logger.debug "popping #{current_container}"
        pop_stack
      end

      pop_stack(Statement::Root)

      @root_statement
    end

    def build_operator_node(token)
      name = token.value
      logger.debug "#{name} is an operator keyword (#{token})"

      # some special cases
      case name
      when "."
        # special case member operator
        build_member_operator(token)
        return
      when "*"
        # `*` can either be multiplication (binary) or splash operator (unary)
        if current_statement.nil? && current_container.is_a?(Statement::ArgumentsList)
          # use unary splash operator
          push_stack Statement::SplashOperator.new(token)
          return
        end
      end

      op = env.operators[name]

      operator = Statement::Operator.new(token, op)

      unless operator.unary?
        operator << remove_current_statement!
      end

      push_stack operator
    end

    def build_attribute_operator(token)
      statement = Statement::Attribute.new(token, remove_current_statement!)

      push_stack statement
    end

    def build_member_operator(token)
      statement = Statement::Attribute.new(token, remove_current_statement!)
      member = next_token
      raise "member operator only allows access through a name, found #{member}" unless member.kind == Kind::NAME
      statement << Statement::Name.new(member)
      statement.member_operator = true
      self.current_statement = statement
    end

    def build_splash_operator(token)
      push_stack operator
    end

    def build_global_function_node(token)
      logger.debug "#{token} is a global function (#{token})"

      function = Statement::Function.new(token)

      build_function_arguments(function)
    end

    def build_local_call_node(token)
      if current_statement.nil?
        # this is not a function call but start of a subexpression, surrounded by parenthesis
        return build_subexpression(token)
      end

      raise "can only call a name statement or attribute statment" unless current_statement.is_a?(Statement::Name | Statement::Attribute)
      function = Statement::Call.new(token, remove_current_statement!)

      push_stack function
    end

    def build_subexpression(token)
      push_stack Statement::Subexpression.new(token)
    end

    def build_variable_node(token)
      logger.debug "#{token} is a variable"
      self.current_statement = Statement::Name.new(token)
    end

    def build_filter_node(token)
      name_token = next_token
      raise "Function musst have a name token" unless name_token.kind == Kind::NAME

      filter = Statement::Filter.new(token, name_token, remove_current_statement!)

      build_function_arguments(filter, call_without_parenthesis: true)
    end

    def build_test_node(token)
      name_token = next_token
      negative_test = false

      if name_token.kind == Kind::NAME && name_token.value == Lexer::Symbol::NOT
        # "is not <test>"
        name_token = next_token
        negative_test = true
      end

      # `none` is identified as a literal for `nil`, but is also the name of a standard test.
      if name_token.kind == Kind::NONE
        name_token.kind = Kind::NAME
      end
      raise "Test musst have a name token (instead: #{name_token})" unless name_token.kind == Kind::NAME

      test = Statement::Test.new(token, name_token, remove_current_statement!)
      test.negative_test = negative_test

      build_function_arguments(test, call_without_parenthesis: true)
    end

    def build_function_call(name_token)
      raise "Function musst have a name token" unless name_token.kind == Kind::NAME

      current_statement
    end

    def build_function_arguments(function, call_without_parenthesis = false)
      peek = peek_token?
      if peek.try(&.kind) == Kind::PARENTHESIS_START
        function.has_parenthesis = true
        next_token
        push_stack function
      elsif call_without_parenthesis
        self.current_statement = function
      else
        self.current_statement = Statement::Name.new(function.token)
      end
    end
  end
end
