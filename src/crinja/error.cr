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

    def initialize(@token, msg : String, name = nil, filename = nil)
      file = ""
      file = " #{filename}" if filename
      super "TemplateSyntaxError: #{msg} @ #{token}#{file}"
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
