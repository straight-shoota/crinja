require "../spec_helper"

describe Crinja::Parser::ExpressionLexer do
  it "tokenizes a simple statement" do
    env = Crinja::Environment.new
    lexer = Crinja::Parser::ExpressionLexer.new(env.config, %("foo" | upper ~ 12))
    tokens = lexer.tokenize
    tokens.map do |token|
      {token.kind, token.value}
    end.should eq([
      {Kind::STRING, "foo"},
      {Kind::PIPE, "|"},
      {Kind::IDENTIFIER, "upper"},
      {Kind::OPERATOR, "~"},
      {Kind::INTEGER, "12"},
      {Kind::EOF, ""},
    ])
  end
end
