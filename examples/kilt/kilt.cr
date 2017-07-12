require "kilt"
require "baked_file_system"
require "crinja"
require "crinja/loader/baked_file_loader"

module Crinja
  macro embed(filename, io_name, *args)
    env = Crinja::Environment.new(loader: Crinja::Loader::BakedFileLoader.new(KiltTemplateFileSystem))
    bindings = {} of String => Crinja::Type

    env.get_template({{ filename }}).render({{ io_name.id }}, {{ *args }})
  end
end

Kilt.register_engine("j2", Crinja.embed)

module KiltTemplateFileSystem
  BakedFileSystem.load("pages", __DIR__)
end

puts Kilt.render("test.j2", {
    from:      "Crinja",
    messenger: "Kilt",
    crinja:    {
      version: Crinja::VERSION,
    },
  })
