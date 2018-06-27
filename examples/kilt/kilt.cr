require "kilt"
require "baked_file_system"
require "crinja"
require "crinja/loader/baked_file_loader"

class Crinja
  macro embed(filename, io_name, *args)
    env = Crinja.new(loader: Crinja::Loader::BakedFileLoader.new(KiltTemplateFileSystem))

    env.get_template({{ filename }}).render({{ io_name.id }}, {{ *args }})
  end
end

Kilt.register_engine("j2", Crinja.embed)

module KiltTemplateFileSystem
  extend BakedFileSystem

  bake_folder("pages")
end

puts Kilt.render("test.j2", {
  from:      "Crinja",
  messenger: "Kilt",
  crinja:    {
    version: Crinja::VERSION,
  },
})
