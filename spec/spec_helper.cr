require "spec"
require "../src/crinja"

alias Kind = Crinja::Lexer::Token::Kind

def parse(string)
  Crinja::Template.new(string)
end

def render(string, bindings = nil, autoescape = nil, loader = nil, trim_blocks = nil, lstrip_blocks = nil)
  env = Crinja::Environment.new
  env.loader = loader unless loader.nil?
  env.config.autoescape.default_for_string = autoescape unless autoescape.nil?
  env.config.trim_blocks = trim_blocks unless trim_blocks.nil?
  env.config.lstrip_blocks = lstrip_blocks unless lstrip_blocks.nil?
  template = env.from_string(string)
  template.render(bindings)
end

def render_load(name, bindings = nil, autoescape = nil, loader = nil, trim_blocks = nil, lstrip_blocks = nil)
  env = Crinja::Environment.new
  env.loader = loader unless loader.nil?
  env.context.autoescape = autoescape unless autoescape.nil?
  env.config.trim_blocks = trim_blocks unless trim_blocks.nil?
  env.config.lstrip_blocks = lstrip_blocks unless lstrip_blocks.nil?
  env.get_template(name).render(bindings)
end

def render(node : Crinja::Node, context : Crinja::Context = Crinja::Context.new)
  env = Crinja::Environment.new(context)

  node.render(env)
end

def render(node : Crinja::Node, bindings)
  casted = Crinja::Bindings.cast(bindings)
  render(node, Crinja::Context.new(casted))
end

def evaluate_statement(string, bindings = nil)
  env = Crinja::Environment.new

  lexer = Crinja::Lexer::StatementLexer.new(env.config, string)
  parser = Crinja::Parser::StatementParser.new(lexer, env.context, logger: env.logger)

  statement = parser.build

  {% if flag?(:debug) %}
    puts statement.inspect
  {% end %}

  unless bindings.nil?
    env.context.merge! Crinja::Bindings.cast(bindings)
  end

  result = statement.evaluate(env)

  if env.context.autoescape?
    result = Crinja::SafeString.escape(result)
  end

  result.to_s
end
