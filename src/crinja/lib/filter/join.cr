class Crinja::Filter
  Crinja.filter({separator: "", attribute: nil}, :join) do
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
            item = arguments.env.resolve_attribute(attribute.to_s, item)
          end
          SafeString.escape(item).to_s(io)
        end
      end
    else
      raise TypeError.new("#{target} must be a list to join it")
    end
  end
end
