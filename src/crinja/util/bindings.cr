module Crinja
  module Bindings
    def self.cast(bindings)
      type_hash = Hash(String, Crinja::Type).new
      bindings.each do |k, v|
        type_hash[k.to_s] = cast_value(v)
      end
      type_hash
    end

    def self.cast_value(value) : Crinja::Type
      case value
      when Hash
        self.cast_hash(value)
      when Array, Tuple
        self.cast_list(value)
      when Range, Iterator
        # TODO: Implement iterator and range trough pyobject `getitem`
        self.cast_list(value.to_a)
      when Char
        value.to_s
      when Value
        value.raw
      else
        value.as(Crinja::Type)
      end
    end

    def self.cast_hash(value) : Crinja::Type
      type_hash = Hash(Crinja::Type, Crinja::Type).new
      value.each do |k, v|
        type_hash[cast_value(k)] = cast_value(v)
      end
      type_hash
    end

    def self.cast_list(array) : Crinja::Type
      array.map do |item|
        cast_value(item).as(Crinja::Type)
      end
    end
  end
end

{% if @type.has_constant?(:JSON) %}
module Crinja::Bindings
  def self.cast_value(value : JSON::Any) : Crinja::Type
    cast_value(value.raw)
  end
end
{% end %}
