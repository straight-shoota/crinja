require "./spec_helper"

describe Crinja::Statement do
  it "resolves a simple variable lookup" do
    token = Crinja::Lexer::Token.new(Crinja::Lexer::Token::Kind::NAME, "foo")
    statement = Crinja::Statement::Name.new(token)

    env = Crinja::Environment.new
    env.context.merge!({"foo" => "bar"})

    statement.evaluate(env).should eq("bar")
  end

  it "resolves lookup sequence" do
    evaluate_statement(%(user.name), {"user" => {"name" => "Barry"}}).should eq("Barry")
  end
end
