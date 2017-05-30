include Crinja

function(:dict) do
  Crinja::Bindings.cast_hash arguments.kwargs
end
