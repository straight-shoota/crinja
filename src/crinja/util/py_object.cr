module Crinja
  module PyObject
    abstract def getattr(attr : Type) : Type

    abstract def getitem(item : Type) : Type
  end
end
