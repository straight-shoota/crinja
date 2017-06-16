module Crinja::Filter
  Crinja.filter({
    case_sensitive: false,
    by:             "key",
  }, :dictsort) do
    case_sensitive = arguments[:case_sensitive].truthy?

    array = target.each.to_a

    compare = ->(a : Value, b : Value) do
      if !case_sensitive && a.string? && b.string?
        a.as_s!.compare(b.as_s!, true)
      else
        a <=> b
      end
    end

    if arguments[:by].to_s == "value"
      array = array.sort { |a, b| compare.call(a[1], b[1]) }
    else
      array = array.sort { |a, b| compare.call(a[0], b[0]) }
    end

    array.map(&.raw.as(Type)).as(Type)
  end
end
