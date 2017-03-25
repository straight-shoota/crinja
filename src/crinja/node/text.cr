class Crinja::Node
  class Text < Node
    property trim_left = false, trim_right = false
    property left_is_block = false, right_is_block = false

    def render(env : Crinja::Environment)
      RenderedOutput.new value(env.config.trim_blocks, env.config.lstrip_blocks)
    end

    def value(trim_blocks = false, lstrip_blocks = false)
      Crinja::StringTrimmer.trim(token.value,
        trim_left || (trim_blocks && left_is_block), trim_right || (lstrip_blocks && right_is_block),
        left_is_block, right_is_block && lstrip_blocks)
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

      io << " left_is_block" if left_is_block
      io << " right_is_block" if right_is_block
    end

    def inspect_children(io : IO, indent = 0)
      io << " " << token.value.inspect
    end
  end
end
