include Crinja

function(:dict) do
  Hash(Type, Type).new.tap do |dict|
    arguments.kwargs.each do |k, val|
      dict[k] = val.raw
    end
  end
end
