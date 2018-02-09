class Crinja
  # :nodoc:
  alias TypeNumber = Float64 | Int64 | Int32
  # :nodoc:
  alias TypeValue = TypeNumber | String | Bool | Time | PyObject | Undefined | Callable | Callable::Proc | SafeString | Nil
  # :nodoc:
  alias TypeContainer = Dictionary | Array(Value) | Iterator(Value)

  alias Dictionary = Hash(Value, Value)
  # class Dictionary < Hash(Value, Value)
  #   def []=(key, value)
  #     self[Value.new(key)] = Value.new value
  #   end

  #   def [](key)
  #     self[Value.new(key)]
  #   end
  # end

  alias Variables = Hash(String, Value)
end
