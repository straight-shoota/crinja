class Crinja::Node
  class Tag < Node
    property tag : Crinja::Tag
    property varargs : Array(Statement) = [] of Statement
    property kwargs : Hash(String, Statement) = Hash(String, Statement).new

    property end_tag_tokens : NamedTuple(start: Token, end: Token)?

    def initialize(start_token : Token, @tag, @varargs, @kwargs)
      super(start_token)
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
      unless (tokens = end_tag_tokens).nil?
        tokens[:end].trim_right
      else
        end_token.try(&.trim_right) || false
      end
    end

    def inspect_arguments(io : IO, indent = 0)
      super(io, indent)
      io << " tag=" << tag.name
      io << " trim?="
      io << if trim_right?
        if trim_left?
          "both"
        else
          "right"
        end
      elsif trim_left?
        "left"
      else
        "none"
      end
    end

    def inspect_end_arguments(io : IO, indent = 0)
      unless (tokens = end_tag_tokens).nil?
        io << " start="
        tokens[:start].inspect(io)
        io << " end="
        tokens[:end].inspect(io)
      end
    end

    def inspect_children(io : IO, indent = 0)
      unless varargs.empty?
        io << "\n" << "  " * indent << "<varargs>"
        varargs.each do |arg|
          io << "\n" << "  " * (indent + 1)
          arg.inspect(io, indent + 1)
        end
        io << "\n" << "  " * indent << "</varargs>"
      end
      unless kwargs.empty?
        kwargs.each do |kw, arg|
          io << "\n" << "  " * indent << "<kwarg name=\"" << kw << "\">"
          io << "\n" << "  " * (indent + 1)
          arg.inspect(io, indent + 1)
          io << "\n" << "  " * indent << "</kwarg>"
        end
      end

      super(io, indent)
    end

    def render(env : Crinja::Environment)
      tag.interpret_output(env, self)
    end

    def validate_argument(index : Int, klass : Class? = nil, token_value : String? = nil)
      raise "Missing argument ##{index} for #{tag_name} tag (#{self.arguments})" if arguments.size < index + 1

      unless token_value.nil?
        actual_value = arguments[index].token.value
        raise "Expected token value #{token_value} for #{tag_name} tag, instead got #{actual_value}" unless token_value === actual_value
      end

      case klass
      when .==(Node::Statement)
        raise "Expected statetement of type #{klass} for #{tag_name} tag, instead got #{arguments[index].class}" unless arguments[index].statement?
        # actual_class = arguments[index].class
        # raise "Expected statement of type #{klass} for #{tag_name} tag, instead got #{actual_class}" unless klass === actual_class
        # if ==Node::Statement
      when nil
        # do nothing
      when .==(Node::Name)
        raise "Expected statetement of type #{klass} for #{tag_name} tag, instead got #{arguments[index].class}" unless arguments[index].name?
      else
        raise "ENGINE ERROR: Validation of #{klass} not implemented"
      end
    end

    def validate_arguments_size(size : Int)
      raise "Expected #{size} arguments for #{tag_name} tag, instead got #{arguments.size}" unless size === arguments.size
    end
  end
end
