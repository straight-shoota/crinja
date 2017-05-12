require "xml"

class Crinja::Filter
  create_filter(Upper) { target.to_s.upcase }

  create_filter(Lower) { target.to_s.downcase }

  create_filter(Capitalize) { target.to_s.capitalize }

  create_filter Center, {width: 80} do
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

  create_filter Striptags do
    xml = XML.parse_html target.to_s
    xml.inner_text.gsub(/\s+/, " ").strip
  end

  create_filter(Format) { sprintf target.to_s, arguments.varargs }

  create_filter Indent, {
    width:       4,
    indentfirst: false,
  } do
    indent = " " * arguments[:width].to_i
    nl = "\n" + indent
    string = target.to_s
    string = indent + string if arguments[:indentfirst].truthy?
    string.gsub(/\n/, nl)
  end
end
