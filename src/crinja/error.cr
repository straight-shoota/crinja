module Crinja
  class TemplateError < Exception
  end

  class TemplateNotFoundError < TemplateError
    def initialize(name, loader, message = "")
      super "template #{name} could not be found by #{loader}. #{message}"
    end

    def initialize(templates : Array, loader)
      super "templates #{templates.inspect} could not be found by #{loader}"
    end
  end

  class TemplateSyntaxError < TemplateError
    getter token : Lexer::Token
    property token_stream : Lexer::TokenStream?

    def initialize(@token, msg : String, name = nil, filename = nil)
      super "TemplateSyntaxError: #{msg}"
    end

    def message
      String.build do |io|
        io << super << "\n"
        io << "@ " << token
        io << "\n" << "\n"

        if (ts = token_stream).nil?
          io << token.value
        else
          (-5..5).each do |n|
            t = ts.peek_token?(n)
            io << " " if t.try(&.whitespace_before)
            io << t.value unless t.nil?
          end
        end
      end
    end
  end

  class RuntimeError < TemplateError
  end

  class TypeError < RuntimeError
  end

  class UndefinedError < RuntimeError
    def initialize(variable_name, msg = nil)
      super "#{variable_name} is undefined. #{msg}"
    end
  end

  class InvalidArgumentException < RuntimeError
    def initialize(callee, msg)
      super "#{msg} (called: #{callee})"
    end
  end

  class TagCycleException < RuntimeError
    def initialize(@type : Symbol)
      super "Tag cycle exception #{@type}"
    end
  end
end
