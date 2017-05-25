class Crinja::Node
  class Text < Node
    property trim_left = false, trim_right = false
    property left_is_block = false, right_is_block = false
  end
end
