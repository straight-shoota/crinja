module Crinja
  class Variable
    property parts : Array(String)

    def initialize(string : String)
      initialize([string])
    end

    def initialize(@parts : Array(String) = [] of String)
    end

    def add_part(name : String)
      parts << name
    end

    def to_s(io : IO)
      is_first = true
      parts.each do |part|
        io << "." unless is_first
        is_first = false
        part.to_s(io)
      end
    end
  end
end
