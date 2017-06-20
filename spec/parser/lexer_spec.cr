require "../spec_helper"

describe Crinja::Parser do
  it "parses a simple template string" do
    config = Crinja::Config.new
    lexer = Crinja::Parser::TemplateLexer.new config, %(Hello World)
    token = lexer.next_token
    token.kind.should eq(Kind::FIXED)
    token.value.should eq("Hello World")
  end

  it "parses a template string with simple expression" do
    config = Crinja::Config.new
    lexer = Crinja::Parser::TemplateLexer.new config, %(Hello {{ name }})
    token = lexer.next_token
    token.kind.should eq(Kind::FIXED)
    token.value.should eq("Hello ")
  end

  it "tokenizes simple template" do
    config = Crinja::Config.new
    lexer = Crinja::Parser::TemplateLexer.new config, %(Hello {{ name | uppercase }}!)

    tokens = lexer.tokenize

    expected = [
      {Kind::FIXED, "Hello "},
      {Kind::EXPR_START, "{{"},
      {Kind::IDENTIFIER, "name"},
      {Kind::PIPE, "|"},
      {Kind::IDENTIFIER, "uppercase"},
      {Kind::EXPR_END, "}}"},
      {Kind::FIXED, "!"},
      {Kind::EOF, ""},
    ]

    tokens.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end

  it "tokenizes template with variable member and filters" do
    config = Crinja::Config.new
    lexer = Crinja::Parser::TemplateLexer.new config, %(Hello, {{ user.name | lower | upper }}!)

    tokens = lexer.tokenize

    expected = [
      {Kind::FIXED, "Hello, "},
      {Kind::EXPR_START, "{{"},
      {Kind::IDENTIFIER, "user"},
      {Kind::POINT, "."},
      {Kind::IDENTIFIER, "name"},
      {Kind::PIPE, "|"},
      {Kind::IDENTIFIER, "lower"},
      {Kind::PIPE, "|"},
      {Kind::IDENTIFIER, "upper"},
      {Kind::EXPR_END, "}}"},
      {Kind::FIXED, "!"},
      {Kind::EOF, ""},
    ]

    tokens.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end

  it "recognizes whitespace trim" do
    lexer = Crinja::Parser::TemplateLexer.new Crinja::Config.new, %( {%- if true -%}\n {{ "Hallo" }}\n  {%- endif %})

    expected = [
      {Kind::FIXED, " "},
      {Kind::TAG_START, "{%-"},
      {Kind::IDENTIFIER, "if"},
      {Kind::BOOL, "true"},
      {Kind::TAG_END, "-%}"},
      {Kind::FIXED, "\n "},
      {Kind::EXPR_START, "{{"},
      {Kind::STRING, "Hallo"},
      {Kind::EXPR_END, "}}"},
      {Kind::FIXED, "\n  "},
      {Kind::TAG_START, "{%-"},
      {Kind::IDENTIFIER, "endif"},
      {Kind::TAG_END, "%}"},
      {Kind::EOF, ""},
    ]

    lexer.tokenize.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end

  it "tokenizes member access with single char name" do
    lexer = Crinja::Parser::TemplateLexer.new Crinja::Config.new, %({{ item.a }})

    expected = [
      {Kind::EXPR_START, "{{"},
      {Kind::IDENTIFIER, "item"},
      {Kind::POINT, "."},
      {Kind::IDENTIFIER, "a"},
      {Kind::EXPR_END, "}}"},
      {Kind::EOF, ""},
    ]

    lexer.tokenize.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end

  it "tokenizes member access with single char name" do
    lexer = Crinja::Parser::ExpressionLexer.new Crinja::Config.new, %(foo(n=n-1))

    expected = [
      {Kind::IDENTIFIER, "foo"},
      {Kind::LEFT_PAREN, "("},
      {Kind::IDENTIFIER, "n"},
      {Kind::KW_ASSIGN, "="},
      {Kind::IDENTIFIER, "n"},
      {Kind::OPERATOR, "-"},
      {Kind::INTEGER, "1"},
      {Kind::RIGHT_PAREN, ")"},
      {Kind::EOF, ""},
    ]

    lexer.tokenize.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end

  it "tokenizes non-ascii" do
    lexer = Crinja::Parser::TemplateLexer.new Crinja::Config.new, %(£{{ "foo" }})
    expected = [
      {Kind::FIXED, "£"},
      {Kind::EXPR_START, "{{"},
      {Kind::STRING, "foo"},
      {Kind::EXPR_END, "}}"},
      {Kind::EOF, ""},
    ]

    lexer.tokenize.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end
end
