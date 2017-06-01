module Crinja::Filter
  Crinja.filter :safe do
    target.raw.is_a?(SafeString) ? target.raw : SafeString.new(target.to_s)
  end
end
