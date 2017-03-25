class Crinja::Node
  class Text < Node
    property trim_left = false, trim_right = false

    def render(io : IO, env : Crinja::Environment)
      io << value
    end

    def value
      Crinja::StringTrimmer.trim(token.value, trim_left, trim_right)
    end

    def inspect_arguments(io : IO, indent = 0)
      super(io, indent)
      io << " trim="
      io << if trim_right
        if trim_left
          "both"
        else
          "right"
        end
      elsif trim_left
        "left"
      else
        "none"
      end
    end

    def inspect_children(io : IO, indent = 0)
      io << " " << token.value.inspect
    end
  end
end
