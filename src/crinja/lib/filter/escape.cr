class Crinja::Filter
  create_filter(Escape) { SafeString.escape(target.to_s) }
end
