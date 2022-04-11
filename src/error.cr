module Crinja::SourceAttached
  MAX_COLUMN_WIDTH = 120

  def message
    String.build do |io|
      msg = super

      if (c = cause).nil?
        io << msg
      else
        if msg.nil?
          io << c.class.to_s << ":  "
        else
          io << msg << "\n"
          io << "cause: "
        end
        io << c.message
      end

      io << "\ntemplate: "

      message_location(io)

      if template = self.template
        io.puts
        io.puts
        highlight_source_code(io)
      end
    end
  end

  def message_location(io)
    if template = self.template
      io << (template.filename || "<string>")
      io << ":" << location_start << " .. " << location_end
    else
      io << "<unknown>"
      io << ":" << location_start
    end
  end

  LINE_MARKER = 'X'

  def highlight_source_code(io, lines_before = 2, lines_after = 2)
    template = @template || return
    location_start = self.location_start || return
    location_end = self.location_end || location_start

    lines = template.source.split('\n')
    line_range = (1..lines.size)
    start_line = (location_start.line - lines_before).clamp(line_range)
    end_line = (location_end.line + lines_after).clamp(line_range)

    linowidth = Math.log(lines.size, 10).ceil.to_i

    (start_line..end_line).each do |i|
      line = lines[i - 1]
      io.printf " %*d | ", linowidth, i
      io << line
      io << '\n'

      linelength = line.size

      if i == location_start.line
        io << " " * (linowidth == 0 ? 1 : linowidth) << LINE_MARKER << " | "
        io << " " * (location_start.column - 1).clamp(0, linelength)
        io << "^"
        if location_end.line == location_start.line
          io << "~" * (location_end.column - location_start.column - 1).clamp(0, linelength)
        end
        io << '\n'
      end
    end
  end
end

class Crinja::Error < Exception
  property template : Template?
  getter location_start : Parser::StreamPosition?
  getter location_end : Parser::StreamPosition?

  include SourceAttached

  def at(@location_start, @location_end)
    self
  end

  def at(node)
    @location_start = node.location_start
    @location_end = node.location_end
    self
  end

  def has_location?
    !location_start.nil?
  end
end

class Crinja::TemplateError < Crinja::Error
  def self.new(token : Parser::Token, cause : Exception? = nil, template = nil)
    new(token, nil, cause, template)
  end

  def initialize(message : String? = nil, cause = nil)
    super(message, cause)
  end

  def initialize(token : Parser::Token, message : String? = nil, cause = nil, @template = nil)
    @location_start = token.location_start
    @location_end = token.location_end
    super(message, cause)
  end

  def initialize(node : AST::ASTNode, message : String? = nil, cause = nil, @template = nil)
    @location_start = node.location_start
    @location_end = node.location_end
    super(message, cause)
  end
end

class Crinja::TemplateNotFoundError < Exception
  def initialize(name, loader = nil, message = "", cause : Exception? = nil)
    super "template #{name} could not be found by #{loader}. #{message}", cause
  end

  def initialize(templates : Array, loader, cause : Exception? = nil)
    super "templates #{templates.inspect} could not be found by #{loader}", cause
  end
end

class Crinja::TemplateSyntaxError < Crinja::TemplateError
end

class Crinja::RuntimeError < Crinja::Error
end

class Crinja::TypeError < Crinja::RuntimeError
  getter value : Value?

  def initialize(@value : Value, msg = "", cause : Exception? = nil)
    initialize msg, cause
  end

  def initialize(msg = "", cause : Exception? = nil)
    super msg, cause
  end
end

class Crinja::UndefinedError < Crinja::RuntimeError
  getter variable_name : String

  def initialize(@variable_name, msg = "", cause : Exception? = nil)
    super msg, cause
  end

  def self.new(undefined : Undefined, msg = "", cause : Exception? = nil)
    new(undefined.name, msg, cause)
  end

  def message
    "#{variable_name} is undefined.#{super}"
  end
end

class Crinja::SecurityError < Crinja::RuntimeError
end
