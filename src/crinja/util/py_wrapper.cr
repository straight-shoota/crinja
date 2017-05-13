require "./py_object"

module Crinja
  module PyyWrapper
    include PyObject

    def getattr(attr : Type) : Type
      Undefined.new(attr.to_s)
    end


    def getitem(item : Type) : Type
      nil
    end

    # macro py_attributes(attributes)
    #  def gettattr(attr : Type)
    #    {% for n in attributes %}
    #    if {{ n }} == attr
    #      return {{ n.id }}
    #    end
    #    {% end %}
    #  end
    # end

  end
end
