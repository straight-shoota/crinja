module Crinja
  class Filter::Safe < Filter
    name "safe"

    def call(target : Any, arguments : Callable::Arguments) : Type
      target.raw.is_a?(SafeString) ? target.raw : SafeString.new(target.to_s)
    end
  end
end
