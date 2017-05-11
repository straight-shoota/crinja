class Crinja::Filter
  class Join < Filter
    name "join"

    arguments({
      :separator => "",
      :attribute => nil,
    })

    def call(target : Value, arguments : Callable::Arguments) : Type
      value = target.raw
      separator = arguments[:separator].to_s
      attribute = arguments[:attribute]
      case value
      # when Enumerable
      #  value.join(separator)
      when Array
        # TODO: Compiler fails with nil assertion if `when Enumerable`
        # it already fails for `value.join("") do |string| string end`
        SafeString.build do |io|
          value.join(separator, io) do |item, io|
            if attribute.truthy?
              if item.responds_to?(:getattr)
                item = item.getattr(attribute.to_s)
              else
                item = Undefined.new(attribute.to_s)
              end
            end
            SafeString.escape(item).to_s(io)
          end
        end
      else
        raise TypeError.new("#{target} must be a list to join it")
      end
    end
  end

  register_default Join
end
