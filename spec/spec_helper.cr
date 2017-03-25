require "spec"
require "../src/crinja"

alias Kind = Crinja::Lexer::Token::Kind

def parse(string)
  Crinja::Template.new(Crinja::Environment.new, string)
end

def render(string, bindings = nil, autoescape = nil, loader = nil)
  env = Crinja::Environment.new
  env.loader = loader unless loader.nil?
  env.context.autoescape = autoescape unless autoescape.nil?
  Crinja::Template.new(env, string).render(bindings)
end

def render(node : Crinja::Node, context : Crinja::Context = Crinja::Context.new)
  env = Crinja::Environment.new(context)

  node.render(env)
end

def render(node : Crinja::Node, bindings)
  casted = Crinja::Bindings.cast(bindings)
  render(node, Crinja::Context.new(casted))
end
