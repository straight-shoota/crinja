require "./py_object"

module Crinja
  module PyWrapper
    include PyObject

    def getattr(attr : Type) : Type
      Undefined.new(attr.to_s)
    end

    macro getattr
      def getattr(attr : Crinja::Type) : Crinja::Type
        {% for method in @type.methods %}
          {% if method.visibility == :public &&
                  (method.name != "each" && method.name != "iterator") &&
                  (method.block_arg.class_name == "Nop") &&
                  # (method.return_type == Type || method.return_type.class_name == "Nop") &&
                  (method.args.empty?) %}
            if {{ method.name.stringify }} == attr
              return {{ method.name }}.as(Crinja::Type)
            end
          {% end %}
        {% end %}

        super(attr)
      end
    end

    macro getattr(*whitelist)
      def getattr(attr : Crinja::Type) : Crinja::Type
        {% for method in whitelist %}
          if {{ method.stringify }} == attr
            return {{ method.id }}.as(Crinja::Type)
          end
        {% end %}

        super(attr)
      end
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
