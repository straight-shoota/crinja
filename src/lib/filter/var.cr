module Crinja::Filter
  Crinja.filter({default_value: "", boolean: false}, :default) do
    default_value = arguments[:default_value]

    value = target.raw
    if target.undefined? || value.nil? || (arguments[:boolean].truthy? && !target.truthy?)
      default_value.raw
    else
      value
    end
  end
  Crinja::Filter::Library.alias :d, :default

  Crinja.filter({name: UNDEFINED}, :attr) do
    Resolver.resolve_getattr(arguments[:name].raw, target)
  end

  # TODO: Use to_json?
  Crinja.filter({verbose: false}, :pprint) do
    env.stringify target, pretty: true
  end
end
