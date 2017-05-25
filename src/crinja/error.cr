module Crinja
  class TemplateError < Exception
    getter token : Lexer::Token
    getter template : Template?

    def initialize(token, cause : Exception? = nil, template = nil)
      initialize(token, nil, cause, template)
    end

    def initialize(@token, message : String? = nil, cause = nil, @template = nil)
      super(message, cause)
    end

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

        io << "\n" << token
        io << "\n\ntemplate: "

        if (t = template).nil?
          io << "<string>"
          io.printf "[%d:%d]\n", token.position.line, token.position.column
        else
          io << t.filename
          io.printf "[%d:%d]", token.position.line, token.position.column
          io << "\n"
          token_source(io)
        end

        io << "\n"
      end
    end

    def token_source(io, lines_before = 2, lines_after = 2)
      template = self.template
      return if template.nil?
      source = template.source
      start_pos = token.position.pos
      before = [] of String
      before = source[0..start_pos - 1].split(Lexer::Symbol::NEWLINE)
      io << before.inspect
      before = before[[0, before.size - 1 - lines_before].max, before.size]

      after = source[(start_pos + token.value.size)..source.size].split(Lexer::Symbol::NEWLINE)
      io << after.inspect
      after = after[0..[lines_after, after.size - 1].min]

      lino = token.position.line
      linowidth = Math.log(lino + after.size, 10).ceil.to_i

      before.each_with_index do |line, i|
        io.printf " %*d | ", linowidth, lino - (before.size - 1) + i
        io << line
        io << "\n" unless i == before.size - 1
      end

      io << token.value

      after.each_with_index do |line, i|
        if i == 1
          io << " " * linowidth
          io << "  | "
          io << " " * (token.position.column - 2)
          io << "/"
          io << "^" * token.value.size
          io << "\\\n"
        end
        io.printf " %*d | ", linowidth, lino + i unless i == 0

        io << line << "\n"
      end
    end
  end

  class TemplateNotFoundError < Exception
    def initialize(name, loader = nil, message = "", cause : Exception? = nil)
      super "template #{name} could not be found by #{loader}. #{message}", cause
    end

    def initialize(templates : Array, loader, cause : Exception? = nil)
      super "templates #{templates.inspect} could not be found by #{loader}", cause
    end
  end

  class TemplateSyntaxError < TemplateError
  end

  class RuntimeError < Exception
  end

  class TypeError < RuntimeError
    getter value : Value?

    def initialize(msg = "", cause : Exception? = nil)
      super msg, cause
    end

    def initialize(@value : Value, msg = "", cause : Exception? = nil)
      super msg, cause
    end
  end

  class UndefinedError < RuntimeError
    getter variable_name : String

    def initialize(@variable_name, msg = nil, cause = nil)
      super msg, cause
    end

    def message
      "#{variable_name} is undefined. #{super}"
    end
  end

  class InvalidArgumentException < RuntimeError
    getter callee : Crinja::Callable | Crinja::Operator | String

    def initialize(callee : Symbol, msg = nil, cause = nil)
      initialize callee.to_s, msg, cause
    end

    def initialize(@callee, msg = nil, cause = nil)
      super msg, cause
    end

    def message
      "#{super} (called: #{callee})"
    end
  end

  class TagCycleException < RuntimeError
    def initialize(@type : Symbol, msg = nil, cause = nil)
      super msg, cause
    end

    def message
      "Tag cycle exception #{@type}. #{super}"
    end
  end
end
