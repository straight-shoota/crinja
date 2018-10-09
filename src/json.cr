require "json"

def Crinja.value(any : JSON::Any) : Crinja::Value
  case raw = any.raw
  when Hash, Array
    value
  else
    value(raw)
  end
end

def Crinja.new(any : JSON::Any) : Crinja::Value
  value(any)
end

struct JSON::Any
  include Crinja::Object

  def crinja_attribute(attr : Crinja::Value) : Crinja::Value
    if @raw.is_a?(Hash) || @raw.is_a?(Array)
      result = self[attr.raw]?
    end
    result ||= Crinja::Undefined.new(attr.to_s)
    return Crinja::Value.new(result)
  end
end
