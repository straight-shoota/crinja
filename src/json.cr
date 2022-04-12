require "json"

def Crinja.value(any : JSON::Any) : Crinja::Value
  value any.raw
end

def Crinja.new(any : JSON::Any) : Crinja::Value
  value(any)
end

struct JSON::Any
  include Crinja::Object

  def crinja_attribute(attr : Crinja::Value) : Crinja::Value
    if @raw.is_a?(Hash) || @raw.is_a?(Array)
      case attr_raw = attr.raw
      when String, Int
        result = self[attr_raw]?
      else
        raise "Expected String or Int for crinja attribute, got #{attr_raw.class}"
      end
    end
    result ||= Crinja::Undefined.new(attr.to_s)
    return Crinja::Value.new(result)
  end
end
