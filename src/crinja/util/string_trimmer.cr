module Crinja
  module StringTrimmer
    def self.trim_simple(string, left = true, right = true)
      return string unless left || right

      string = string.lstrip if left
      string = string.rstrip if right

      string
    end

    def self.trim(string, left = true, right = true)
      return string unless left || right

      orig = string
      String.build do |io|
        if left
          first_line, nl, string = string.partition("\n")

          # if first_line == ""
          #  first_line, nl, string = string.partition("\n")
          # end
          if nl.empty?
            # no newline
            string = first_line.lstrip
          else
            first_line = first_line.lstrip
            io << first_line
            io << nl if first_line.size > 0
          end
        end

        if right
          middle, nl, last_line = string.rpartition("\n")
          io << middle
          last_trimmed = last_line.rstrip

          # It is unclear wether this \n should be stripped or not. Python tests suggest yes,
          # but it would make sense (see example hello_world.html) to keep it. Other sources
          # seem to recognize this trailing slash.
          # io << nl
          io << nl if last_trimmed.size > 0
          io << last_trimmed
        else
          io << string
        end
      end
    end
  end
end
