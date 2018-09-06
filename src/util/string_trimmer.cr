module Crinja::Util::StringTrimmer
  def self.trim_simple(string, left = true, right = true)
    return string unless left || right

    string = string.lstrip if left
    string = string.rstrip if right

    string
  end

  def self.trim(string, left = true, right = true, strip_newline_left = false, strip_newline_right = false)
    return string unless left || right

    String.build do |io|
      if left
        first_line, nl_first, string = string.partition("\n")

        if nl_first.empty?
          # no newline
          string = first_line.lstrip
        else
          first_line = first_line.lstrip
          io << first_line
          io << nl_first unless strip_newline_left
        end
      end

      if right
        middle, nl, last_line = string.rpartition("\n")
        io << middle
        last_trimmed = last_line.rstrip

        # use \n explicitly, so it gets even added if rpartition did not match.
        # This way there will always be a newline included, if the initial string had one newline
        # followed only by whitespace characters.
        # skip_last_newline = nl_first.empty? && !last_trimmed.empty?
        # nl = "\"
        io << nl unless strip_newline_right # || skip_last_newline
        io << last_trimmed
      else
        io << string
      end
    end
  end
end
