require "xml"

module Crinja::Filter
  Crinja.filter(:upper) { target.to_s.upcase }

  Crinja.filter(:lower) { target.to_s.downcase }

  Crinja.filter(:capitalize) { target.to_s.capitalize }

  Crinja.filter({width: 80}, :center) do
    string = target.to_s
    width = arguments[:width].to_i
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

  Crinja.filter :striptags do
    xml = XML.parse_html target.to_s
    xml.inner_text.gsub(/\s+/, " ").strip
  end

  Crinja.filter(:format) { sprintf target.to_s, arguments.varargs }

  Crinja.filter({
    width:       4,
    indentfirst: false,
  }, :indent) do
    indent = " " * arguments[:width].to_i
    nl = "\n" + indent
    string = target.to_s
    string = indent + string if arguments[:indentfirst].truthy?
    string.gsub(/\n/, nl)
  end

  Crinja.filter(:string) { target.to_s }

  Crinja.filter(:title) do
    target.to_s.gsub(/[^#{Crinja::Util::REGEX_WORD.source}]+/, &.capitalize)
  end

  Crinja.filter({length: 255, killwords: false, end: "...", leeway: nil}, :truncate) do
    length = arguments[:length].to_i
    fin = arguments[:end].to_s
    end_size = fin.size
    raise "expected length >= #{end_size}, got #{length}" if length < end_size
    leeway = arguments.fetch(:leeway) { env.policies.fetch("truncate.leeway", 5) }.to_i
    raise "expected leeway >= 0, got #{leeway}" if leeway < 0
    killwords = arguments[:killwords].truthy?

    s = target.to_s
    if s.size <= length + leeway
      s
    else
      trimmed = s[0, length - end_size]
      trimmed = trimmed.rpartition(' ').first unless killwords
      trimmed + fin
    end
  end

  Crinja.filter(:wordcount) do
    target.to_s.split(/[#{Crinja::Util::REGEX_WORD.source}]+/).size
  end
end

module Crinja::Util
  REGEX_WORD = /\s-\(\{\[\</
end
