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
  Crinja::Filter::Library.defaults["d"] = Crinja::Filter::Library.defaults["default"]

  Crinja.filter({name: nil}, :attr) do
    Resolver.resolve_getattr(arguments[:name].raw, target)
  end

  # TODO: Use to_json?
  Crinja.filter({verbose: false}, :pprint) do
    if arguments[:verbose].truthy?
      target.pretty_inspect
    else
      target.pretty_inspect
    end
  end

  Crinja.filter(:random) do
    target.as_indexable.sample
  end

  Crinja.filter(:map) do
    if target.none?
      ""
    elsif arguments.is_set?("attribute")
      attribute = arguments[:attribute].raw
      target.map do |item|
        Resolver.resolve_getattr(attribute, item).as(Type)
      end.as(Type)
    else
      varargs = arguments.varargs
      filter = env.filters[varargs.shift.as_s!]
      args = Arguments.new(env, varargs, arguments.kwargs, target: target)

      target.map do |item|
        args.target = item
        filter.call(args).as(Type)
      end
    end
  end
end
