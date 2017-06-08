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

  Crinja.filter(:title) { target.to_s.gsub(/[^-\s\(\{\[\<]+/, &.capitalize) }
end
