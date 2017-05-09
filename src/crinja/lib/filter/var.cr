module Crinja
  class Filter::Default < Filter
    name "default"

    arguments({
      :default_value => "",
      :boolean       => false,
    })

    def call(target : Value, arguments : Callable::Arguments) : Type
      default_value = arguments[:default_value]

      value = target.raw
      if target.undefined? || value.nil? || (arguments[:boolean].truthy? && !target.truthy?)
        default_value.raw
      else
        value
      end
    end
  end

  class Filter::List < Filter
    name "list"

    def call(target : Value, arguments : Callable::Arguments) : Type
      value = target.raw

      case value
      when String
        value.chars.map(&.to_s.as(Type))
      when Array
        value
      else
        raise TypeError.new("target for list filter cannot be converted to list")
      end
    end
  end

  class Filter::Batch < Filter
    name "batch"

    arguments({
      :linecount => 2,
      :fill_with => nil,
    })

    def call(target : Value, arguments : Callable::Arguments) : Type
      value = target.raw
      fill_with = arguments[:fill_with].raw
      linecount = arguments[:linecount].to_i

      case value
      when Array
        array = Array(Type).new

        value.each_slice(linecount) do |slice|
          (linecount - slice.size).times { slice << fill_with } unless fill_with.nil?
          array << slice
        end

        array
      else
        raise TypeError.new("target for batch filter must be a list")
      end
    end
  end

  class Filter::Slice < Filter
    name "slice"

    arguments({
      :slices    => 2,
      :fill_with => nil,
    })

    def call(target : Value, arguments : Callable::Arguments) : Type
      fill_with = arguments[:fill_with].raw
      slices = arguments[:slices].to_i
      raw = target.raw

      case raw
      when Array(Type)
        values = [] of Type
        raw.each do |val|
          values << val.as(Type)
        end
        array = Array(Type).new

        num_full_slices = values.size % slices
        per_slice = values.size / slices

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
  end

  class Filter::First < Filter
    name "first"

    def call(target : Value, arguments : Callable::Arguments) : Type
      target[0].raw
    end
  end
end
