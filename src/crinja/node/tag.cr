class Crinja::Node
  class Tag < Node
    property name_token : Token
    property tag : Crinja::Tag
    property varargs : Array(Statement) = [] of Statement
    property kwargs : Hash(String, Statement) = Hash(String, Statement).new

    property end_tag : Tag?

    def initialize(start_token : Token, @name_token, @end_token, @tag, @varargs, @kwargs)
      super(start_token)
    end

    def end_token
      super.not_nil!
    end

    def name
      tag.name
    end

    def block?
      true
    end

    def end_name
      if (tag = @tag).responds_to?(:end_tag_for)
        tag.end_tag_for(self)
      else
        @tag.end_tag
      end
    end

    def trim_right_after_end?
      unless (end_tag = @end_tag).nil?
        end_tag.end_token.trim_right
      else
        end_token.try(&.trim_right) || false
      end
    end
  end
end
