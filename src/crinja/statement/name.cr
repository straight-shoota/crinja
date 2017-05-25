class Crinja::Statement
  class Name < Statement
    def name
      token.value
    end
  end
end
