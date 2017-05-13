class Crinja::Filter
  create_filter(Escape, default: true) { SafeString.escape(target.to_s) }
  register_default Escape, "e"
end
