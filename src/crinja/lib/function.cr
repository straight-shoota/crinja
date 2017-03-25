require "./importable"
require "./callable"
require "./feature_library"

module Crinja
  abstract class Function
    include Callable
    include Importable

    class Library < FeatureLibrary(Function)
      register_defaults [Dict, Range]
    end
  end
end

require "./function/*"
