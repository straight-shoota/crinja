module Crinja
  module Bindings
    def self.cast(bindings)
      type_hash = Hash(String, Crinja::Type).new
      bindings.each do |k, v|
        type_hash[k.to_s] = self.cast_value(v)
      end
      type_hash
    end

    def self.cast_value(value) : Crinja::Type
      case value
      when Hash
        self.cast_hash(value)
      when Array
        self.cast_list(value)
      when Range, Iterator
        self.cast_list(value.to_a)
      when Tuple
        self.cast_list(value)
      when Char
        value.to_s
      when Any
        value.raw
      else
        value.as(Crinja::Type)
      end
    end

    def self.cast_hash(value) : Crinja::Type
      type_hash = Hash(Crinja::Type, Crinja::Type).new
      value.each do |k, v|
        type_hash[self.cast_value(k)] = self.cast_value(v)
      end
      type_hash
    end

    def self.cast_list(array) : Crinja::Type
      array.map do |item|
        self.cast_value(item).as(Crinja::Type)
      end
    end
  end
end
