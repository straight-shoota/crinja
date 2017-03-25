module Crinja
  class Error < Exception
  end

  class TemplateNotFoundError < Error
    def initialize(template, loader)
      super "template #{template} could not be found by #{loader}"
    end

    def initialize(templates : Array, loader)
      super "templates #{templates.inspect} could not be found by #{loader}"
    end
  end

  class TemplateSyntaxError < Error
    getter token : Lexer::Token

    def initialize(@token, msg : String)
      super("TemplateSyntaxError: #{msg} @ #{token}")
    end
  end

  class RuntimeException < Error
  end

  class TypeError < RuntimeException
  end

  class UndefinedError < RuntimeException
    def initialize(variable_name, msg = nil)
      super "#{variable_name} is undefined. #{msg}"
    end
  end

  class InvalidArgumentException < RuntimeException
    def initialize(callee, msg)
      super "#{msg} (called: #{callee})"
    end
  end
end
