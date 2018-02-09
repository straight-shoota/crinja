module Crinja::Filter
  Crinja.filter :list do
    value = target.raw

    case value
    when String
      value.chars
    when Array
      value
    when .responds_to?(:to_a)
      target.to_a
    else
      raise TypeError.new("target for list filter cannot be converted to list")
    end
  end

  Crinja.filter({linecount: 2, fill_with: nil}, :batch) do
    fill_with = arguments[:fill_with]
    linecount = arguments[:linecount].to_i

    if target.sequence?
      array = [] of Value
      batch = [] of Value

      target.each do |item|
        batch << item

        if batch.size == linecount
          array << Value.new batch
          batch = [] of Value
        end
      end

      unless batch.empty?
        (linecount - batch.size).times { batch << fill_with } unless fill_with.none?
        array << Value.new batch
      end

      array
    else
      raise TypeError.new("target for batch filter must be a sequence")
    end
  end

  Crinja.filter({slices: 2, fill_with: nil}, :slice) do
    fill_with = arguments[:fill_with]
    slices = arguments[:slices].to_i

    if target.sequence?
      array = [] of Value
      slice = [] of Value

      num_full_slices = target.size % slices
      per_slice = target.size / slices
      per_full_slice = per_slice + 1

      target.each do |item|
        slice << item

        if array.size < num_full_slices ? slice.size == per_full_slice : slice.size == per_slice
          array << Value.new slice

          if array.size > num_full_slices
            slice << fill_with unless fill_with.none?
          end

          slice = [] of Value
        end
      end

      unless slice.empty?
        array << Value.new slice
      end

      array
    else
      raise TypeError.new("target for batch filter must be a list")
    end
  end

  Crinja.filter(:first) { target.first.raw }
  Crinja.filter(:last) { target.last.raw }
  Crinja.filter(:length) { target.size }
  Crinja::Filter::Library.alias "count", "length"

  Crinja.filter(:reverse) do
    reversable = target.raw

    if reversable.responds_to?(:reverse_each)
      # FIXME: `to_a` should not be necessary, but without it creates a silent memory failure
      reversable.reverse_each.to_a
    elsif reversable.responds_to?(:reverse)
      reversable.reverse
    else
      raise TypeError.new(target, "#{target.raw.class} cannot be reversed")
    end
  end

  Crinja.filter({attribute: nil, start: 0}, :sum) do
    attribute = arguments[:attribute].as_s?

    start = arguments[:start].as_number
    sum = start

    target.each do |value|
      unless attribute.nil?
        value = Resolver.resolve_dig(attribute, value)
      end

      raw = value.raw
      if raw.is_a?(Crinja::TypeNumber)
        sum += raw
      else
        raise TypeError.new("cannot add #{raw.class} to sum, value: #{raw.inspect}")
      end
    end

    sum
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
        Resolver.resolve_getattr(attribute, item)
      end
    else
      varargs = arguments.varargs
      filter = env.filters[varargs.shift.as_s!]
      args = Callable::Arguments.new(env, varargs, arguments.kwargs)

      target.map do |item|
        args.target = item
        arguments.env.execute_call(filter, args)
      end
    end
  end

  # :nodoc:
  macro select_reject_attr(func)
    varargs = arguments.varargs

    attribute = varargs.shift

    if varargs.size == 0
      # select based on attribute value, no filter
      target.{{ func.id }} do |item|
        Resolver.resolve_getattr(attribute, item).truthy?
      end
    else
      test = env.tests[varargs.shift.as_s!]
      args = Callable::Arguments.new(env, varargs, arguments.kwargs)

      target.{{ func.id }} do |item|
        args.target = Resolver.resolve_getattr(attribute, item)
        env.execute_call(test, args).truthy?
      end
    end
  end

  # :nodoc:
  macro select_reject(func)
    varargs = arguments.varargs

    if varargs.size == 0
      # select based on actual value, no filter
      target.{{ func.id }} &.truthy?
    else
      test = env.tests[varargs.shift.as_s!]
      args = Callable::Arguments.new(env, varargs, arguments.kwargs)

      target.{{ func.id }} do |item|
        args.target = item
        env.execute_call(test, args).truthy?
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

  Crinja.filter({attribute: UNDEFINED}, :groupby) do
    attribute = arguments[:attribute]

    Dictionary.new.tap do |dict|
      target.each do |item|
        value = Crinja::Value.new Resolver.resolve_dig(attribute, item)
        if dict.has_key?(value)
          dict[value].as_a.push(item)
        else
          dict[value] = Crinja::Value.new [item] of Value
        end
      end
    end
  end
end
