require "spec"
require "../../src/crinja"

def evaluate_statement(string, bindings = nil)
  env = Crinja::Environment.new

  lexer = Crinja::Lexer::StatementLexer.new(env.config, string)
  parser = Crinja::Parser::StatementParser.new(lexer, env.context)

  statement = parser.build

  unless bindings.nil?
    env.context.merge! Crinja::Bindings.cast(bindings)
  end

  result = statement.evaluate(env)

  if env.context.autoescape?
    result = Crinja::SafeString.escape(result)
  end

  result.to_s
end
