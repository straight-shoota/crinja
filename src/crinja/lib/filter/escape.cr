module Crinja::Filter
  Crinja.filter(:escape) do
    raw = target.raw
    if raw.is_a?(SafeString)
      raw
    else
      SafeString.escape(raw.to_s)
    end
  end
  Crinja::Filter::Library.defaults["e"] = Crinja::Filter::Library.defaults["escape"]

  Crinja.filter(:forceescape) { SafeString.escape(target.to_s) }

  Crinja.filter :safe do
    target.raw.is_a?(SafeString) ? target.raw : SafeString.new(target.to_s)
  end
end
