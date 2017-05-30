require "spec"
require "../src/crinja"

alias Kind = Crinja::Parser::Token::Kind

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

def load(name, autoescape = nil, loader = nil, trim_blocks = nil, lstrip_blocks = nil)
  env = Crinja::Environment.new
  env.loader = loader unless loader.nil?
  env.context.autoescape = autoescape unless autoescape.nil?
  env.config.trim_blocks = trim_blocks unless trim_blocks.nil?
  env.config.lstrip_blocks = lstrip_blocks unless lstrip_blocks.nil?
  env.get_template(name)
end

def render_load(name, bindings = nil, autoescape = nil, loader = nil, trim_blocks = nil, lstrip_blocks = nil)
  load(name, autoescape, loader, trim_blocks, lstrip_blocks).render(bindings)
end

def evaluate_expression(string, bindings = nil, autoescape = nil)
  env = Crinja::Environment.new
  env.config.autoescape.default_for_string = autoescape unless autoescape.nil?

  lexer = Crinja::Parser::ExpressionLexer.new(env.config, string)

  parser = Crinja::Parser::ExpressionParser.new(lexer)

  expression = parser.parse

  unless bindings.nil?
    env.context.merge! Crinja::Bindings.cast(bindings)
  end

  result = env.evaluate expression

  if env.config.autoescape?
    result = Crinja::SafeString.escape(result)
  end

  result.to_s
end
