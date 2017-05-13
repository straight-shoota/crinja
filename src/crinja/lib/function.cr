require "./importable"
require "./callable"
require "./feature_library"

module Crinja
  abstract class Function
    include Crinja::Callable
    include Crinja::Importable

    class Library < FeatureLibrary(Function)
    end

    macro register_default(defaults, name = nil)
      class Library
        register_default {{ defaults }}, {{ name }}
      end
    end
  end
end

require "./function/*"
