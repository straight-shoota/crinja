class Crinja::Filter
  create_filter Safe, default: true do
    target.raw.is_a?(SafeString) ? target.raw : SafeString.new(target.to_s)
  end
end
