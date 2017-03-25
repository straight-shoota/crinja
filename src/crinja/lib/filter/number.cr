module Crinja
  class Filter::Abs < Filter
    name "abs"

    def call(target : Any, arguments : Arguments) : Type
      raw = target.raw
      if raw.is_a?(Float64 | Int32)
        raw.abs
      else
        raise InvalidArgumentException.new(self, "Cannot render abs value for #{raw.class}, only accepts numbers")
      end
    end
  end

  class Filter::Float < Filter
    name "float"

    arguments({
      :default => 0.0,
    })

    def call(target : Any, arguments : Arguments) : Type
      target.to_f
    rescue ArgumentError
      arguments[:default].to_f
    end
  end
end
