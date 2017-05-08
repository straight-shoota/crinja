require "./importable"
require "./callable"
require "./feature_library"

module Crinja
  abstract class Function
    include Crinja::Callable
    include Crinja::Importable

    class Library < FeatureLibrary(Function)
      register_defaults [Dict, Range, Super]
    end
  end
end

require "./function/*"
