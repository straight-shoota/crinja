module Crinja::Filter
  Crinja.filter(:escape) { SafeString.escape(target.to_s) }
  Crinja::Filter::Library.defaults["e"] = Crinja::Filter::Library.defaults["escape"]
end
