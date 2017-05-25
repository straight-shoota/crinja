class Crinja::Statement
  class Function < Statement
    include ArgumentsList

    def name
      token.value
    end
  end
end
