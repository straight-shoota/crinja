class Crinja::Function
  class Dict < Function
    def call(arguments : Arguments) : Type
      Hash(Type, Type).new.tap do |dict|
        arguments.kwargs.each do |k, val|
          dict[k] = val.raw
        end
      end
    end
  end

  register_default Dict
end
