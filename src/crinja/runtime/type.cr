module Crinja
  # :nodoc:
  alias TypeNumber = Float64 | Int64 | Int32
  # :nodoc:
  alias TypeValue = TypeNumber | String | Bool | Time | PyObject | Undefined | Callable | Callable::Proc | SafeString | Nil
  # :nodoc:
  alias TypeContainer = Hash(Type, Type) | Array(Type) | Iterator(Type)

  alias Type = TypeValue | TypeContainer
end
