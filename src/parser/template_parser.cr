class Crinja::Parser::TemplateParser
  include ParserHelper

  @trim_left = false
  @left_is_block = false
  @last_sibling_fixed : AST::FixedString?

  def self.new(template : Template)
    new(template.env, template.source)
  end

  def initialize(@env : Crinja, source)
    @token_stream = TokenStream.new(TemplateLexer.new(@env.config, source))
    @logger = @env.logger
    @expression_parser = ExpressionParser.new(@token_stream, @env.config)
    @stack = [] of ::Tuple(AST::TagNode, String)
  end

  def config
    @env.config
  end

  # Parses a template.
  def parse
    @stack = [] of ::Tuple(AST::TagNode, String)

    list = parse_node_list

    if @stack.size > 0
      raise TemplateSyntaxError.new(@stack.last[0], "Unclosed tag, missing: #{@stack.map(&.[1]).join ", "}")
    end

    list
  end

  private def parse_node_list(block = false)
    nodes = Array(AST::TemplateNode).new

    start_location = current_token.location

    while true
      if last_node = nodes.last?
        last_node.location_end = current_token.location
      end
      case current_token.kind
      when Kind::EOF
        break
      else
        node = parse_node

        @last_sibling_fixed = if node.is_a?(AST::FixedString)
                                node
                              else
                                nil
                              end

        if node.is_a?(AST::EndTagNode)
          if @stack.size > 0
            parent, expected_end_name = @stack.last

            if node.name == expected_end_name
              parent.end_tag = node
              @stack.pop
            else
              raise TemplateSyntaxError.new(node, "Mismatched end tag: #{node.name}")
            end
          else
            raise TemplateSyntaxError.new(node, "End tag without start: #{node.name}")
          end

          break
        end

        nodes << node
      end
    end

    @last_sibling_fixed = nil

    end_location = nodes.last.location_end if nodes.size > 0

    AST::NodeList.new(nodes, block).at(start_location, end_location)
  end

  private def parse_node
    case current_token.kind
    when Kind::FIXED
      parse_fixed_string
    when Kind::EXPR_START
      parse_print_statement
    when Kind::TAG_START
      parse_tag
    when Kind::NOTE
      parse_note
    else
      unexpected_token
    end
  end

  private def parse_fixed_string
    node = AST::FixedString.new(
      current_token.value,
      @trim_left, @left_is_block,
      false, false
    ).at(current_token.location)

    @trim_left = false
    @left_is_block = false

    next_token
    # if (sibling = last_sibling).nil?
    #  node.trim_left = @parent.trim_right
    #  node.left_is_block = @parent.block?
    # else
    #  node.trim_left = sibling.trim_right_after_end?
    #  node.left_is_block = sibling.block?
    # end

    node
  end

  private def parse_note
    set_trim(current_token.trim_right, current_token.trim_left, true)

    note = current_token.value
    next_token

    AST::Note.new(note)
  end

  private def parse_print_statement
    trim_left = current_token.trim_left
    start_location = current_token.location
    next_token
    expression = @expression_parser.parse(Kind::EXPR_END)

    expect Kind::EXPR_END
    end_location = current_token.location
    set_trim(current_token.trim_right, trim_left)

    AST::PrintStatement.new(expression).at(start_location, end_location)
  end

  private def parse_tag
    start_location = current_token.location
    trim_right = current_token.trim_left
    next_token

    assert_token Kind::IDENTIFIER do
    end
    name_token = current_token

    tag = @env.tags[name_token.value]

    if tag.nil?
      raise TemplateSyntaxError.new(name_token, "unknown tag: #{name_token.value}")
    end

    next_token
    arguments = [] of Token
    while current_token.kind != Kind::TAG_END
      arguments << current_token
      next_token
    end
    arguments << Token.new(Kind::EOF, "", current_token.location)

    end_location = current_token.location
    trim_left = current_token.trim_right
    expect Kind::TAG_END

    set_trim(trim_left, trim_right, true)

    if tag.is_a?(Tag::EndTag)
      node = AST::EndTagNode.new(name_token.value, arguments).at(start_location, end_location)

      return node
    else
      block = AST::NodeList.new([] of AST::TemplateNode, true)

      node = AST::TagNode.new(name_token.value, arguments, block, nil).at(start_location, end_location)

      if tag.has_block?(node)
        @stack << {node, tag.end_tag.not_nil!}
        node.block = parse_node_list(true)
      end

      return node
    end
  end

  private def set_trim(trim_left, trim_right, is_block = false)
    @trim_left = trim_left
    @left_is_block = is_block

    unless (sibling = @last_sibling_fixed).nil?
      sibling.trim_right = trim_right
      sibling.right_is_block = is_block
    end
  end

  # private def set_trim_for_last_child(trim, is_block = false)
  #  if (children = last_sibling.try(&.children)) && children.size > 0 && (child = children.last).is_a?(Node::Text)
  #    child.trim_right = trim
  #    child.right_is_block = is_block
  #  end
  # end
end
