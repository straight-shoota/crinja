module Crinja::PyObject
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
    end
  end

  macro getattr(*whitelist)
    def getattr(attr : Crinja::Type) : Crinja::Type
      {% for method in whitelist %}
        if {{ method.stringify }} == attr
          return {{ method.id }}.as(Crinja::Type)
        end
      {% end %}
    end
  end
end
