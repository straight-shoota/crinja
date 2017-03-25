module Crinja
  class Function::Dict < Function
    name "dict"

    def call(arguments : Arguments) : Type
      Hash(Type, Type).new.tap do |dict|
        arguments.kwargs.each do |k, val|
          dict[k] = val.raw
        end
      end
    end
  end
end
