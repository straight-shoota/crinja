module Crinja::Filter
  # These filters provide compatibility with Liquid filters.

  Crinja.filter({string: UNDEFINED}, :prepend) do
    String.build do |io|
      io << arguments[:string]
      io << target
    end
  end

  Crinja.filter({string: UNDEFINED}, :append) do
    String.build do |io|
      io << target
      io << arguments[:string]
    end
  end

  Crinja.filter({format: Crinja::UNDEFINED}, :date) do
    target.as_time.to_s(arguments[:format].to_s)
  end
end
