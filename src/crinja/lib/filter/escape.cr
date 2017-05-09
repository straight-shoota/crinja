module Crinja
  class Filter::Escape < Filter
    name "escape"

    def call(target : Value, arguments : Callable::Arguments) : Type
      SafeString.escape(target.raw)
    end
  end
end
