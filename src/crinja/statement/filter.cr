class Crinja::Statement
  class Filter < Statement
    getter target, name_token

    include ArgumentsList

    def initialize(token : Crinja::Lexer::Token, @name_token : Crinja::Lexer::Token, @target : Statement)
      super(token)
      target.parent = self
    end

    def name
      @name_token.value
    end
  end
end
