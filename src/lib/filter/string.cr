{% unless flag?(:win32) %}require "xml"{% end %}

module Crinja::Filter
  Crinja.filter(:upper) { target.to_s.upcase }

  Crinja.filter(:lower) { target.to_s.downcase }

  Crinja.filter(:capitalize) { target.to_s.capitalize }

  Crinja.filter({width: 80}, :center) do
    string = target.to_s
    width = arguments["width"].to_i
    if string.size >= width
      string
    else
      pad_width = width - string.size
      left_pad = (pad_width / 2).floor

      String.build do |io|
        io << " " * left_pad
        string.to_s(io)
        io << " " * (pad_width - left_pad)
      end
    end
  end

  {% unless flag?(:win32) %}
  Crinja.filter :striptags do
    xml = XML.parse_html target.to_s
    xml.inner_text.gsub(/\s+/, " ").strip
  end
  {% end %}

  Crinja.filter(:format) { sprintf target.to_s, arguments.varargs }

  Crinja.filter({
    width:       4,
    indentfirst: false,
  }, :indent) do
    indent = " " * arguments["width"].to_i
    nl = "\n" + indent
    string = target.to_s
    string = indent + string if arguments["indentfirst"].truthy?
    string.gsub(/\n/, nl)
  end

  Crinja.filter(:string) { env.stringify target }

  Crinja.filter(:title) do
    target.to_s.gsub(/[^#{Crinja::Util::REGEX_WORD.source}]+/, &.capitalize)
  end

  Crinja.filter({length: 255, killwords: false, end: "...", leeway: nil}, :truncate) do
    length = arguments["length"].to_i
    append = arguments["end"].to_s
    end_size = append.size
    raise "expected length >= #{end_size}, got #{length}" if length < end_size
    leeway = arguments.fetch("leeway") { env.policies.fetch("truncate.leeway", 5) }.to_i
    raise "expected leeway >= 0, got #{leeway}" if leeway < 0
    killwords = arguments["killwords"].truthy?

    if leeway >= length
      # if string has very short length, don't use leeway and kill words
      leeway = 0
      killwords = true unless arguments.is_set?(:killwords)
    end

    s = target.to_s
    if s.size <= length + leeway
      s
    else
      trimmed = s[0, length - end_size]
      trimmed = trimmed.rpartition(' ').first unless killwords
      trimmed + append
    end
  end

  Crinja.filter(:wordcount) do
    target.to_s.split(/[#{Crinja::Util::REGEX_WORD.source}]+/).size
  end

  Crinja.filter({old: UNDEFINED, new: UNDEFINED, count: nil}, :replace) do
    search = arguments["old"].to_s
    replace = arguments["new"]
    count = arguments["count"]

    if count.raw.nil?
      target.as_s.gsub(search, replace)
    else
      string = target.to_s
      count.to_i.times do
        running = false
        string = string.sub(search) { running = true; replace }
        break unless running
      end
      string
    end
  end

  Crinja.filter(:trim) do
    target.as_s.strip
  end

  Crinja.filter({width: 79, break_long_words: true, wrapstring: nil}, :wordwrap) do
    width = arguments["width"].to_i
    break_long_words = arguments["break_long_words"].truthy?
    wrapstring = arguments.fetch("wrapstring", "\n").to_s

    String.build do |io|
      first_line = true
      target.as_s.each_line do |line|
        io << wrapstring unless first_line
        first_line = false
        while line.size > width
          newline = line[0, width]
          if break_long_words
            io << newline
          else
            newline, s, _ = newline.rpartition(/\s/)
            io << newline << s
          end
          io << wrapstring
          line = line[newline.size..-1]
        end
        io << line
      end
    end
  end
end

module Crinja::Util
  REGEX_WORD = /\s-\(\{\[\</
end
