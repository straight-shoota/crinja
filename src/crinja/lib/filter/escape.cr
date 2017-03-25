module Crinja
  class Filter::Escape < Filter
    name "escape"

    def call(target : Any, arguments : Callable::Arguments) : Type
      SafeString.escape(target.raw)
    end
  end
end
