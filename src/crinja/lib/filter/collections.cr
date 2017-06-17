module Crinja::Filter
  Crinja.filter :list do
    value = target.raw

    case value
    when String
      value.chars.map(&.to_s.as(Type))
    when Array
      value
    when .responds_to?(:to_a)
      value.to_a
    else
      raise TypeError.new("target for list filter cannot be converted to list")
    end
  end

  Crinja.filter({linecount: 2, fill_with: nil}, :batch) do
    fill_with = arguments[:fill_with].raw
    linecount = arguments[:linecount].to_i

    if target.sequence?
      array = Array(Type).new

      target.raw_each.each_slice(linecount) do |slice|
        (linecount - slice.size).times { slice << fill_with } unless fill_with.nil?
        array << slice
      end

      array
    else
      raise TypeError.new("target for batch filter must be a sequence")
    end
  end

  Crinja.filter({slices: 2, fill_with: nil}, :slice) do
    fill_with = arguments[:fill_with].raw
    slices = arguments[:slices].to_i

    if target.sequence?
      values = target.raw_each.to_a
      array = Array(Type).new

      num_full_slices = target.size % slices
      per_slice = target.size / slices

      num_full_slices.times do |i|
        slice = Array(Type).new
        values[i * (per_slice + 1), per_slice + 1].each do |v|
          slice << v.as(Type)
        end
        array << slice
      end

      (slices - num_full_slices).times do |i|
        slice = values[(num_full_slices + i) * per_slice + num_full_slices, per_slice]
        slice << fill_with unless fill_with.nil?
        array << slice
      end

      array
    else
      raise TypeError.new("target for batch filter must be a list")
    end
  end

  Crinja.filter(:first) { target.first.raw }
  Crinja.filter(:last) { target.last.raw }
  Crinja.filter(:length) { target.size }

  Crinja.filter(:reverse) do
    reversable = target.raw
    if reversable.responds_to?(:reverse_each)
      reversable.reverse_each
    elsif reversable.responds_to?(:reverse)
      reversable.reverse
    else
      raise TypeError.new(target, "#{target.raw.class} cannot be reversed")
    end
  end

  Crinja.filter({attribute: nil, start: 0}, :sum) do
    attribute = arguments[:attribute].as_s?

    start = arguments[:start].as_number
    target.raw_each.reduce(start) do |memo, item|
      unless attribute.nil?
        item = Resolver.resolve_dig(attribute, item)
      end

      if item.is_a?(Crinja::TypeNumber)
        memo + item
      else
        raise TypeError.new("cannot add #{item.class} to sum, value: #{item.inspect}")
      end
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
      args = Arguments.new(env, varargs, arguments.kwargs)

      target.map do |item|
        args.target = item
        filter.call(args).as(Type)
      end
    end
  end

  macro select_reject_attr(func)
    varargs = arguments.varargs
    iterable = target.as_iterable

    attribute = varargs.shift.raw

    if varargs.size == 0
      # select based on attribute value, no filter
      iterable.{{ func.id }} do |item|
        Value.truthy? Resolver.resolve_getattr(attribute, item)
      end
    else
      test = env.tests[varargs.shift.as_s!]
      args = Arguments.new(env, varargs, arguments.kwargs)

      iterable.{{ func.id }} do |item|
        args.target = Value.new Resolver.resolve_getattr(attribute, item)
        Value.truthy? test.call(args)
      end
    end
  end

  macro select_reject(func)
    varargs = arguments.varargs
    iterable = target.as_iterable

    if varargs.size == 0
      # select based on actual value, no filter
      iterable.{{ func.id }} do |item|
        Value.truthy? item
      end
    else
      test = env.tests[varargs.shift.as_s!]
      args = Arguments.new(env, varargs, arguments.kwargs)

      iterable.{{ func.id }} do |item|
        args.target = Value.new item
        Value.truthy? test.call(args)
      end
    end
  end

  Crinja.filter(:select) do
    Crinja::Filter.select_reject(:select)
  end

  Crinja.filter(:reject) do
    Crinja::Filter.select_reject(:reject)
  end

  Crinja.filter(:selectattr) do
    Crinja::Filter.select_reject_attr(:select)
  end

  Crinja.filter(:rejectattr) do
    Crinja::Filter.select_reject_attr(:reject)
  end

  Crinja.filter({attribute: nil}, :groupby) do
    attribute = arguments[:attribute].raw

    h = Hash(Type, Type).new
    target.raw_each do |item|
      value = Resolver.resolve_dig(attribute, item)
      if h.has_key?(value)
        h[value].as(Array).push(item)
      else
        h[value] = [item.as(Type)].as(Type)
      end
    end
    h
  end
end
