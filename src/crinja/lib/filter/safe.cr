class Crinja::Filter
  create_filter Safe do
    target.raw.is_a?(SafeString) ? target.raw : SafeString.new(target.to_s)
  end
end
