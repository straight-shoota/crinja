module Crinja::Filter
  Crinja.filter :abs do
    if target.number?
      target.as_number.abs
    else
      raise Callable::ArgumentError.new("abs", "Cannot render abs value for #{target.raw.class}, only accepts numbers")
    end
  end

  Crinja.filter({default: 0.0}, :float) do
    begin
      target.to_f
    rescue ArgumentError
      arguments[:default].to_f
    end
  end

  Crinja.filter({default: 0, base: 10}, :int) do
    begin
      if arguments.target!.string?
        string = arguments.target!.as_s
        if string['.']?
          string.to_f(arguments[:base].to_i).to_i
        else
          string.to_i(arguments[:base].to_i, prefix: true)
        end
      else
        target.to_i
      end
    rescue ArgumentError
      arguments[:default].to_i
    end
  end

  Crinja.filter({binary: false}, :filesizeformat) do
    Crinja::Filter::Filesizeformat.filesize_to_human(target.to_f, arguments[:binary].truthy?)
  end

  class Filesizeformat
    def self.filesize_to_human(size, binary = false)
      if binary
        {
          "Bytes" => 1024_i64,
          "KiB"   => 1024_i64 ** 2,
          "MiB"   => 1024_i64 ** 3,
          "GiB"   => 1024_i64 ** 4,
          "TiB"   => 1024_i64 ** 5,
          "PiB"   => 1024_i64 ** 6,
        }
      else
        {
          "Bytes" => 1000_i64,
          "kB"    => 1000_i64 ** 2,
          "MB"    => 1000_i64 ** 3,
          "GB"    => 1000_i64 ** 4,
          "TB"    => 1000_i64 ** 5,
          "PB"    => 1000_i64 ** 6,
        }
      end.each do |unit, magnitude|
        if size < magnitude
          return String.build do |io|
            converted = (size / (magnitude / (binary ? 1024 : 1000)))
            if unit == "Bytes"
              io << converted.to_i
            else
              io << converted.round(1)
            end
            io << " "
            io << unit
          end
        end
      end
    end
  end

  Crinja.filter({precision: 0, method: "common", base: 10}, :round) do
    precision = arguments[:precision].to_i
    value = target.as_number
    base = arguments[:base].as_number
    base = base.to_f if precision < 0

    case arguments[:method].as_s
    when "common"
      value.round(precision, base)
    when "ceil"
      multi = base ** precision
      (value * multi).ceil / multi
    when "floor"
      multi = base ** precision
      (value * multi).floor / multi
    else
      raise Callable::ArgumentError.new("method", "argument `method` for filter `round` must be 'common', 'ceil' or 'floor'")
    end
  end
end
