class Crinja::Statement
  class Call < Statement
    property target : Statement

    include ArgumentsList

    def initialize(token, @target)
      super(token)
      target.parent = self
    end
  end
end
