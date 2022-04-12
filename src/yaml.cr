require "yaml"

def Crinja.value(any : YAML::Any) : Crinja::Value
  value any.raw
end

def Crinja.new(any : YAML::Any) : Crinja::Value
  value(any)
end

struct YAML::Any
  include Crinja::Object

  def crinja_attribute(attr : Crinja::Value) : Crinja::Value
    if @raw.is_a?(Hash) || @raw.is_a?(Array)
      result = self[attr.raw]?
    end
    result ||= Crinja::Undefined.new(attr.to_s)
    return Crinja::Value.new(result)
  end
end
