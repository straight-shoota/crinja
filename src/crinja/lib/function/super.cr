# This function is a special language construct because it needs access to the renderer which is
# generally not available in expressions. Therefore it must be the one and only expression in a
# `AST::PrintStatement` (`{{ super() }}`).
Crinja.function(:super) do
  raise Crinja::RuntimeError.new("call to global function `super()` must be the only expression in a print statement")
end
