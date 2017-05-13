class Crinja::Filter
  create_filter Abs, default: true do
    if target.number?
      target.as_number.abs
    else
      raise InvalidArgumentException.new(self, "Cannot render abs value for #{target.raw.class}, only accepts numbers")
    end
  end

  create_filter Float, {default: 0.0}, default: true do
    begin
      target.to_f
    rescue ArgumentError
      arguments[:default].to_f
    end
  end

  create_filter Filesizeformat, {binary: false}, default: true do
    self.class.filesize_to_human(target.to_f, arguments[:binary].truthy?)
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
end
