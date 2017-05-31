abstract class Crinja::Tag
  # :nodoc:
  alias TagNode = AST::TagNode
  # :nodoc:
  alias Kind = Parser::Token::Kind

  include Importable

  def interpret_output(renderer : Renderer, tag_node : TagNode)
    Renderer::RenderedOutput.new(String.build do |io|
      interpret(io, renderer, tag_node)
    end)
  end

  private def interpret(io : IO, renderer : Renderer, tag_node : TagNode)
    raise "Tag#interpret needs to be implemented by #{self.class}"
  end

  def end_tag : String?
    nil
  end

  macro name(name, end_tag = nil)
    def name : String
      {{ name }}
    end

    def end_tag : String?
      {{ end_tag }}
    end
  end

  def has_block?(node : TagNode)
    !end_tag.nil?
  end

  class Library < FeatureLibrary(Tag)
    TAGS = [If, Else, Elif, For,
            Set, Filter,
            Macro, Call,
            Raw,
            Include, From, Import,
            Extends, Block]

    def register_defaults
      TAGS.each do |name|
        tag = name.new
        self << tag
      end
    end

    def <<(tag)
      super(tag)
      unless (end_tag = tag.end_tag).nil?
        super(EndTag.new(tag, end_tag))
      end
    end
  end

  # This is a helper class for `Tag` implementations to parse tag arguments. It can either be used
  # directly or be subclassed for more complex parsing.
  class ArgumentsParser < Parser::ExpressionParser
    # :nodoc:
    alias Kind = Crinja::Parser::Token::Kind

    def initialize(arguments)
      @token_stream = Parser::TokenStream.new(arguments)
      @pos = 0
    end

    include Parser::ParserHelper

    def expect_identifier
      unless current_token.kind == Kind::IDENTIFIER
        raise TemplateSyntaxError.new(current_token, "Unexpected #{current_token}, expected identifier expression")
      else
        name = current_token.value

        next_token

        return name
      end
    end

    def expect_identifier(name)
      unless current_token.kind == Kind::IDENTIFIER && current_token.value == name
        raise TemplateSyntaxError.new(current_token, "Unexpected #{current_token}, expected identifier expression `#{name}`")
      end

      next_token
    end

    def expect_identifier(names : Array(String))
      name = current_token.value
      unless current_token.kind == Kind::IDENTIFIER && names.includes? name
        raise TemplateSyntaxError.new(current_token, "Unexpected #{current_token}, expected identifier expression `#{names.join("`, `")}`")
      end

      next_token

      name
    end

    def if_identifier(name)
      if current_token.kind == Kind::IDENTIFIER && current_token.value == name
        yield
      end
    end

    def if_identifier(names : Array(String))
      if current_token.kind == Kind::IDENTIFIER && names.includes? current_token.value
        yield
      end
    end
  end
end

require "./tag/*"
