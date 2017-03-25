require "./spec_helper"

describe Crinja::Lexer do
  it "parses a simple template string" do
    config = Crinja::Config.new
    lexer = Crinja::Lexer::TemplateLexer.new config, %(Hello World)
    token = lexer.next_token
    token.kind.should eq(Kind::FIXED)
    token.value.should eq("Hello World")
  end

  it "parses a template string with simple expression" do
    config = Crinja::Config.new
    lexer = Crinja::Lexer::TemplateLexer.new config, %(Hello {{ name }})
    token = lexer.next_token
    token.kind.should eq(Kind::FIXED)
    token.value.should eq("Hello ")
  end

  it "tokenizes simple template" do
    config = Crinja::Config.new
    lexer = Crinja::Lexer::TemplateLexer.new config, %(Hello {{ name | uppercase }}!)

    tokens = lexer.tokenize

    expected = [
      {Kind::FIXED, "Hello "},
      {Kind::EXPR_START, "{{"},
      {Kind::NAME, "name"},
      {Kind::PIPE, "|"},
      {Kind::NAME, "uppercase"},
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
    lexer = Crinja::Lexer::TemplateLexer.new config, %(Hello, {{ user.name | lower | upper }}!)

    tokens = lexer.tokenize

    expected = [
      {Kind::FIXED, "Hello, "},
      {Kind::EXPR_START, "{{"},
      {Kind::NAME, "user"},
      {Kind::OPERATOR, "."},
      {Kind::NAME, "name"},
      {Kind::PIPE, "|"},
      {Kind::NAME, "lower"},
      {Kind::PIPE, "|"},
      {Kind::NAME, "upper"},
      {Kind::EXPR_END, "}}"},
      {Kind::FIXED, "!"},
      {Kind::EOF, ""},
    ]

    tokens.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end

  it "recognizes whitespace trim" do
    lexer = Crinja::Lexer::TemplateLexer.new Crinja::Config.new, %( {%- if true -%}\n {{ "Hallo" }}\n  {%- endif %})

    expected = [
      {Kind::FIXED, " "},
      {Kind::TAG_START, "{%-"},
      {Kind::NAME, "if"},
      {Kind::BOOL, "true"},
      {Kind::TAG_END, "-%}"},
      {Kind::FIXED, "\n "},
      {Kind::EXPR_START, "{{"},
      {Kind::STRING, "Hallo"},
      {Kind::EXPR_END, "}}"},
      {Kind::FIXED, "\n  "},
      {Kind::TAG_START, "{%-"},
      {Kind::NAME, "endif"},
      {Kind::TAG_END, "%}"},
      {Kind::EOF, ""},
    ]

    lexer.tokenize.map do |token|
      {token.kind, token.value}
    end.should eq(expected)
  end
end
