require "crinja"
require "yaml"

class Crinja::ResolvedDict(T)
  def self.from_yaml(source)
    new YAML.parse(source).as_h
  end

  getter dictionary : Hash(YAML::Any, YAML::Any)
  getter env : Crinja

  def initialize(@dictionary, @env = Crinja.new)
  end

  delegate keys, to: dictionary

  def [](key)
    resolve raw(key)
  end

  def []=(key, value)
    self[YAML::Any.new key] = YAML::Any.new value
  end

  def []=(key : YAML::Any, value : YAML::Any)
    @dictionary[key] = value
  end

  def raw(key)
    raw(YAML::Any.new key)
  end

  def raw(key : YAML::Any)
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
