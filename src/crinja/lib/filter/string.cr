module Crinja
  class Filter::Uppercase < Filter
    name "upper"

    def call(target : Value, arguments : Function::Arguments) : Type
      target.to_s.upcase
    end
  end

  class Filter::Lowercase < Filter
    name "lower"

    def call(target : Value, arguments : Function::Arguments) : Type
      target.to_s.downcase
    end
  end

  class Filter::Capitalize < Filter
    name "capitalize"

    def call(target : Value, arguments : Function::Arguments) : Type
      target.to_s.capitalize
    end
  end

  class Filter::Center < Filter
    name "center"

    arguments({
      :width => 80,
    })

    def call(target : Value, arguments : Function::Arguments) : Type
      string = target.to_s
      width = arguments[:width].to_i
      return string if string.size >= width

      pad_width = width - string.size
      left_pad = (pad_width / 2).floor

      String.build do |io|
        io << " " * left_pad
        string.to_s(io)
        io << " " * (pad_width - left_pad)
      end
    end
  end

  class Filter::Striptags < Filter
    name "striptags"

    def call(target : Value, arguments : Function::Arguments) : Type
      xml = XML.parse_html target.to_s
      xml.inner_text.gsub(/\s+/, " ").strip
    end
  end

  class Filter::Format < Filter
    name "format"

    def call(target : Value, arguments : Function::Arguments) : Type
      sprintf target.to_s, arguments.varargs
    end
  end

  class Filter::Indent < Filter
    name "indent"

    arguments({
      :width       => 4,
      :indentfirst => false,
    })

    def call(target : Value, arguments : Function::Arguments) : Type
      indent = " " * arguments[:width].to_i
      nl = "\n" + indent
      string = target.to_s
      string = indent + string if arguments[:indentfirst].truthy?
      string.gsub(/\n/, nl)
    end
  end
end
