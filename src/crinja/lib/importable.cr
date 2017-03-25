module Crinja
  module Importable
    abstract def name : String

    macro name(name)
      def name : String
        {{ name }}
      end
    end
  end
end
