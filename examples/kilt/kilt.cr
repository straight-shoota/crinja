require "kilt"
require "baked_file_system"
require "../../src/crinja"

module Crinja
  macro embed(filename, io_name)
    env = Crinja::Environment.new(loader: Crinja::BakedTemplateLoader.new)
    bindings = {} of String => Crinja::Type

    bindings = self.to_bindings if self.responds_to?(:to_bindings)

    env.get_template({{ filename }}).render({{ io_name.id }}, bindings)
  end

  macro bake_file_system(path, dir = nil)
    class Crinja::BakedTemplateLoader < Crinja::Loader
      BakedFileSystem.load({{ path }}, {{ dir }})

      def get_source(env, template)
        file = self.class.get(template)
        return file.read, file.path
      end

      def list_templates
        self.class.files.each
      end
    end
  end
end

Kilt.register_engine("j2", Crinja.embed)

Crinja.bake_file_system("pages", __DIR__)

class CrinjaView
  # TODO: Enable view object as context main scope
  def to_bindings
    Crinja::Bindings.cast_bindings({
      from:      "Crinja",
      messenger: "Kilt",
      crinja:    {
        version: Crinja::VERSION,
      },
    })
  end

  Kilt.file("test.j2")
end

puts CrinjaView.new.to_s
