class Crinja::Filter
  Crinja.filter({
    case_sensitive: false,
    by:             "key",
  }, :dictsort) do
    hash = target.as_h
    array = [] of Tuple(Value, Value)
    sort_by_key = arguments[:by] != "value"
    hash.each do |key, value|
      array << {Value.new(key), Value.new(value)}
    end

    array.sort do |(ak, av), (bk, kv)|
      ak <=> bk
    end

    # case_sensitive = arguments[:case_sensitive].truthy?
    # if arguments[:by].to_s == "value"
    #  hash.to_a.sort do |(ak, av), (bk, bv)|
    #    Value.new(av) <=> Value.new(bv)
    #  end
    # else
    #  array.as(Array(Tuple(Crinja::Type, Crinja::Type))).sort do |(ak, av), (bk, kv)|
    #    Value.new(ak) <=> Value.new(bk)
    #  end
    # end.as(Array(Tuple(Crinja::Type, Crinja::Type))).map(&.to_a.as(Crinja::Type))
    # Bindings.cast_list(array)
    #[] of Type
    #type_array = [] of Array(Crinja::Type)
    #array.each do |key, value|
    #  type_array << [key.raw, value.raw]
    #end
    #type_array
    [] of Crinja::Type
  end
end
