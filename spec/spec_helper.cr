require "spec"
require "../src/crinja"

alias Kind = Crinja::Parser::Token::Kind

def parse(string)
  Crinja::Template.new(string)
end

def parse_expression(string)
  env = Crinja::Environment.new
  begin
    lexer = Crinja::Parser::ExpressionLexer.new(env.config, string)
    parser = Crinja::Parser::ExpressionParser.new(lexer)
    parser.parse
  rescue e : Crinja::TemplateError
    e.template = Crinja::Template.new(string, env, run_parser: false)
    raise e
  end
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

  env.evaluate(string, bindings)
end

def evaluate_expression_raw(string, bindings = nil, autoescape = nil)
  env = Crinja::Environment.new
  env.context.autoescape = autoescape unless autoescape.nil?
  lexer = Crinja::Parser::ExpressionLexer.new(env.config, string)
  parser = Crinja::Parser::ExpressionParser.new(lexer)

  expression = parser.parse

  env.evaluate expression, bindings
end

module Spec
  # :nodoc:
  struct BeInExpectation(T)
    def initialize(@expected_container : T)
    end

    def match(actual_value)
      @expected_container.includes?(actual_value)
    end

    def failure_message(actual_value)
      "Expected:   #{@expected_container.inspect}\nto include: #{actual_value.inspect}"
    end

    def negative_failure_message(actual_value)
      "Expected: value #{@expected_container.inspect}\nto not include: #{actual_value.inspect}"
    end
  end

  module Expectations
    def be_in(value)
      Spec::BeInExpectation.new(value)
    end
  end
end
