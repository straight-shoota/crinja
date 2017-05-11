module Crinja
  module Importable
    # Determines the name of this importable. Defaults to lower case name of the class.
    def name : String
      {{ @type.stringify.split("::").last.downcase }}
    end

    # Set a name that differs from the class name.
    macro name(name)
      def name
        {{ name }}
      end
    end
  end
end
