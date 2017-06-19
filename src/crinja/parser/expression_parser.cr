require "logger"
require "./parser_helper"

class Crinja::Parser::ExpressionParser
  include ParserHelper

  # Helper macro to prevent duplicate code for operator precedence parsing
  macro parse_operator(name, next_operator, *operators)
    private def parse_{{name.id}}
        left = parse_{{next_operator.id}}

        while true
          if current_token.kind == Kind::OPERATOR
            case current_token.value
            when {{
                   *operators.map { |field|
                     "Symbol::OP_#{field.id}".id
                   }
                 }}
              operator = current_token.value
              next_token
              right = parse_{{next_operator.id}}
              left = ({{ yield }}).at(left, right)
            else
              return left
            end
          else
            return left
          end
        end
      end
  end

  def parse(expected_end_token : Kind = Kind::EOF)
    case current_token.kind
    when expected_end_token
      # there is no content in this expression
      return AST::Empty.new
    else
      expression = parse_expression

      if current_token.kind != expected_end_token
        raise "expression was not fully parsed: #{current_token}"
      end

      expression
    end
  end

  def parse_expressions(expected_end_token : Kind = Kind::EOF)
    expressions = Array(ExpressionNode).new
    while true
      case current_token.kind
      when expected_end_token
        return AST::Expressions.new(expressions).at(current_token.location)
      else
        list = parse_expression_list([expected_end_token])
        if list.children.size == 1
          expressions << list.children[0]
        else
          expressions << list
        end
      end
    end
  end

  def parse_expression
    parse_logical_or
  end

  parse_operator :logical_or, :logical_and, OR do
    AST::BinaryExpression.new operator, left, right
  end
  parse_operator :logical_and, :equal_not, AND do
    AST::BinaryExpression.new operator, left, right
  end
  parse_operator :equal_not, :less_greater, EQUAL, NOT_EQUAL, NOT do
    AST::ComparisonExpression.new operator, left, right
  end
  parse_operator :less_greater, :tilde, LESS, GREATER, LESS_EQUAL, GREATER_EQUAL do
    AST::ComparisonExpression.new operator, left, right
  end
  parse_operator :tilde, :add_sub, TILDE do
    AST::BinaryExpression.new operator, left, right
  end
  parse_operator :add_sub, :mult_div, PLUS, MINUS do
    AST::BinaryExpression.new operator, left, right
  end
  parse_operator :mult_div, :mod, TIMES, DIV, INT_DIV do
    AST::BinaryExpression.new operator, left, right
  end
  parse_operator :mod, :filter, MODULO do
    AST::BinaryExpression.new operator, left, right
  end

  private def parse_filter
    left = parse_unary_expression

    while true
      case current_token.kind
      when Kind::PIPE, Kind::TEST
        is_test = current_token.kind == Kind::TEST

        next_token

        not_location = nil
        if is_test
          if_token Kind::OPERATOR, "not" do
            not_location = current_token.location

            next_token
          end
        end

        identifier = if_token(Kind::NONE) do
          AST::IdentifierLiteral.new(current_token.value).at(current_token.location)
        end || assert_token Kind::IDENTIFIER do
          AST::IdentifierLiteral.new(current_token.value).at(current_token.location)
        end
        next_token

        with_parenthesis = false
        if !is_test && current_token.kind == Kind::LEFT_PAREN
          next_token
          with_parenthesis = true
        end

        call = parse_call_expression identifier, with_parenthesis: with_parenthesis

        if is_test
          left = AST::TestExpression.new(left, identifier, call.argumentlist, call.keyword_arguments).at(left, call)

          if not_location
            left = AST::UnaryExpression.new("not", left).at(not_location)
          end
        else
          left = AST::FilterExpression.new(left, identifier, call.argumentlist, call.keyword_arguments).at(left, call)
        end
      else
        return left
      end
    end
  end

  private def parse_unary_expression
    start_location = current_token.location

    if current_token.kind == Kind::OPERATOR
      case operator = current_token.value
      when Symbol::OP_PLUS, Symbol::OP_MINUS, Symbol::OP_NOT
        next_token
        value = parse_unary_expression
        return AST::UnaryExpression.new(operator, value).at(start_location, value.location_end)
      when Symbol::OP_TIMES
        # splash operator
        next_token
        value = parse_unary_expression
        return AST::SplashOperator.new(value).at(start_location, value.location_end)
      end
    end

    parse_pow
  end

  private def parse_pow
    left = parse_parenthesis_expression
    while true
      if (current_token.kind == Kind::OPERATOR) && (current_token.value == Parser::Symbol::OP_POW)
        operator = current_token.value
        next_token
        right = parse_unary_expression
        left = AST::BinaryExpression.new(operator, left, right).at(left, right)
      else
        return left
      end
    end
  end

  private def parse_parenthesis_expression
    if_token Kind::LEFT_PAREN do
      # parse subexpression in parenthesis
      start_location = current_token.location

      next_token

      expression = parse_expression

      if current_token.kind == Kind::COMMA
        # we're in a tuple with only single parenthesis
        next_token

        exps = parse_expression_list([Kind::RIGHT_PAREN])
        entries = exps.children
        entries.unshift expression

        end_location = current_token.location

        expression = AST::TupleLiteral.new(entries).at(start_location, end_location)
      end
      expect Kind::RIGHT_PAREN

      return expression
    end

    parse_variable_expression
  end

  private def parse_variable_expression
    identifier = parse_literal
    while true
      case current_token.kind
      when Kind::LEFT_PAREN
        next_token
        identifier = parse_call_expression(identifier)
      when Kind::LEFT_BRACKET
        next_token
        arg = parse_expression

        end_location = current_token.location
        expect Kind::RIGHT_BRACKET
        identifier = AST::IndexExpression.new(identifier, arg).at(identifier.location_start, end_location)
      when Kind::POINT
        next_token
        member = AST::Empty.new

        if current_token.kind == Kind::IDENTIFIER || current_token.kind == Kind::INTEGER
          member = AST::IdentifierLiteral.new(current_token.value).at(current_token.location)
          next_token
        else
          unexpected_token Kind::IDENTIFIER
        end

        if member.is_a? AST::IdentifierLiteral
          identifier = AST::MemberExpression.new(identifier, member).at(identifier, member)
        end
      else
        return identifier
      end
    end
  end

  private def parse_call_expression(identifier, with_parenthesis = true)
    end_tokens = if with_parenthesis
                   [Kind::RIGHT_PAREN]
                 else
                   [Kind::EOF, Kind::EXPR_END, Kind::TAG_END, Kind::OPERATOR, Kind::PIPE, Kind::TEST, Kind::RIGHT_BRACKET, Kind::RIGHT_PAREN]
                 end

    args = parse_expression_list(end_tokens)

    keyword = nil
    if_token Kind::KW_ASSIGN do
      keyword = args.children.pop
    end

    kwargs = if keyword
               parse_keyword_list(end_tokens, keyword: keyword)
             else
               Hash(AST::IdentifierLiteral, AST::ExpressionNode).new
             end

    end_location = current_token.location
    expect Kind::RIGHT_PAREN if with_parenthesis
    AST::CallExpression.new(identifier, args, kwargs).at(identifier.location_start, end_location)
  end

  private def parse_literal
    case current_token.kind
    when Kind::LEFT_PAREN
      next_token
      node = parse_expression
      expect Kind::RIGHT_PAREN
    when Kind::IDENTIFIER
      node = parse_identifier
    when Kind::INTEGER
      node = AST::IntegerLiteral.new(current_token.value.to_i64).at(current_token.location)
      next_token
    when Kind::FLOAT
      node = AST::FloatLiteral.new(current_token.value.to_f64).at(current_token.location)
      next_token
    when Kind::STRING
      node = AST::StringLiteral.new(current_token.value).at(current_token.location)
      next_token
    when Kind::BOOL
      node = AST::BooleanLiteral.new(current_token.value.downcase == "true").at(current_token.location)
      next_token
    when Kind::NONE
      node = AST::NullLiteral.new.at(current_token.location)
      next_token
    when Kind::LEFT_BRACKET
      node = parse_array_literal
    when Kind::LEFT_CURLY
      node = parse_dict_literal
    else
      unexpected_token value: "an expression"
    end

    return node
  end

  private def parse_identifier
    node = AST::IdentifierLiteral.new(current_token.value).at(current_token.location)
    next_token
    node
  end

  private def parse_expression_list(end_tokens : Array(Kind))
    exps = [] of AST::ExpressionNode
    start_location = current_token.location

    should_read = !end_tokens.includes? current_token.kind
    while should_read
      should_read = false

      exps << parse_expression

      if current_token.kind == Kind::COMMA
        should_read = true
        next_token
      end
    end

    end_location = exps.last?.try(&.location_end) || start_location

    return AST::ExpressionList.new(exps).at(start_location, end_location)
  end

  def parse_keyword_list(end_tokens : Array(Kind) = [Kind::EOF], keyword_separator_token : Kind = Kind::KW_ASSIGN, keyword = nil)
    hash = Hash(AST::IdentifierLiteral, AST::ExpressionNode).new

    should_read = !end_tokens.includes? current_token.kind
    while should_read
      should_read = false

      if keyword.nil?
        keyword = parse_literal
      end

      if keyword.is_a?(AST::IdentifierLiteral)
        expect keyword_separator_token

        value = parse_expression

        hash[keyword] = value
      else
        unexpected_token Kind::IDENTIFIER
      end

      keyword = nil

      if current_token.kind == Kind::COMMA
        should_read = true
        next_token
      end
    end

    hash
  end

  private def parse_array_literal
    start_location = current_token.location

    expect Kind::LEFT_BRACKET
    exps = parse_expression_list([Kind::RIGHT_BRACKET])

    end_location = current_token.location
    expect Kind::RIGHT_BRACKET
    return AST::ArrayLiteral.new(exps.children).at(start_location, end_location)
  end

  private def parse_dict_literal
    start_location = current_token.location

    expect Kind::LEFT_CURLY

    hash = Hash(AST::ExpressionNode, AST::ExpressionNode).new

    should_read = current_token.kind != Kind::RIGHT_CURLY

    while should_read
      should_read = false

      key = parse_expression
      expect Kind::DICT_ASSIGN
      value = parse_expression

      hash[key] = value

      if current_token.kind == Kind::COMMA
        should_read = true
        next_token
      end
    end

    end_location = current_token.location

    expect Kind::RIGHT_CURLY

    return AST::DictLiteral.new(hash).at(start_location, end_location)
  end

  private def parse_identifier_list
    list = [] of AST::IdentifierLiteral

    while true
      list << parse_identifier

      break if current_token.kind != Kind::COMMA
      next_token
    end

    list
  end
end
