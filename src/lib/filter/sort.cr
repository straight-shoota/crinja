module Crinja::Filter
  Crinja.filter({
    case_sensitive: false,
    by:             "key",
  }, :dictsort) do
    case_sensitive = arguments[:case_sensitive].truthy?

    array = target.to_a

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

    array
  end

  Crinja.filter({
    reverse:        false,
    case_sensitive: false,
    attribute:      nil,
  }, :sort) do
    case_sensitive = arguments[:case_sensitive].truthy?

    array = target.to_a

    attribute = nil

    if arguments[:attribute].string?
      attribute = arguments[:attribute].as_s!
    end

    array = array.sort do |a, b|
      unless attribute.nil?
        a = a[attribute.not_nil!]
        b = b[attribute.not_nil!]
      end

      if !case_sensitive && a.string? && b.string?
        a.as_s!.compare(b.as_s!, true)
      else
        a <=> b
      end
    end

    if arguments[:reverse].truthy?
      array = array.reverse
    end

    array
  end
end
