module Crinja::Filter
  Crinja.filter({separator: "", attribute: nil}, :join) do
    value = target.raw
    separator = arguments[:separator].to_string
    attribute = arguments[:attribute]

    case value
    # when Enumerable
    #  value.join(separator)
    when Array
      # TODO: Compiler fails with nil assertion if `when Enumerable`
      # it already fails for `value.join("") do |string| string end`
      do_attribute = attribute.truthy?
      attr_name = attribute.to_s
      SafeString.build do |io|
        value.join(separator, io) do |item, io|
          if do_attribute
            item = Resolver.resolve_attribute(attr_name, item)
          end
          io << Stringifier.stringify(item, env.context.autoescape?)
        end
      end
    else
      raise TypeError.new("#{target} must be a list to join it")
    end
  end
end
