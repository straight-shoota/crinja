module Crinja::Filter
  Crinja.filter({separator: "", attribute: nil}, :join) do
    separator = arguments["separator"].to_string
    attribute = arguments["attribute"]

    if target.sequence?
      # TODO: Compiler fails with nil assertion if `when Enumerable`
      # it already fails for `value.join("") do |string| string end`
      do_attribute = attribute.truthy?
      attr_name = attribute.to_s
      SafeString.build do |io|
        target.join(separator, io) do |item|
          if do_attribute
            item = Resolver.resolve_attribute(attr_name, item)
          end
          io << env.stringify(item)
        end
      end
    else
      raise TypeError.new("#{target} must be a sequence to join it")
    end
  end
end
