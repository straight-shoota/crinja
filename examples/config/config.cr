require "crinja"
require "yaml"

class Crinja::ResolvedDict(T)
  def self.from_yaml(source)
    new YAML.parse(source).raw.as(Hash(YAML::Type, YAML::Type))
  end

  getter dictionary : Hash(YAML::Type, YAML::Type)
  getter env : Crinja::Environment

  def initialize(@dictionary, @env = Crinja::Environment.new)
  end

  delegate keys, to: dictionary

  def [](key)
    resolve raw(key)
  end

  def []=(key, value)
    @dictionary[key] = value
  end

  def raw(key)
    @dictionary[key]
  end

  def resolve(expression)
    template = env.from_string(expression.to_s)
    if template.dynamic?
      resolve(template.render(dictionary))
    else
      expression
    end
  end

  def resolve_all
    keys.map do |key|
      [key, self[key]]
    end.to_h
  end
end

config = Crinja::ResolvedDict(String | Int32).from_yaml <<-'YAML'
  foo: "bar"
  baz: "{{ foo | upper }}"
  num: 1
  YAML

pp config["baz"] # => "BAR"
config["foo"] = "{{ 'foo' ~ num }}"
pp config["baz"] # => "FOO1"
pp config.resolve_all
