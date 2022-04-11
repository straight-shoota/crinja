require "baked_file_system"

# A loader that retrieves templates from a [Baked File System](https://github.com/schovi/baked_file_system).
# This way templates can be baked directly into the executable, so there is no need to provide
# separate templates files. However, this prevents modifying templates at runtime.
# Both can be accomplished by using a `ChoiceLoader` to combine a `FileSystemLoader` with
# baked files as a fallback/default template loader.
#
# Usage depends on the shard [schovi/baked_file_system](https://github.com/schovi/baked_file_system)
# and this class must be explicitly required as `crinja/loader/baked_file_loader`.
#
# ## Usage:
#
# ```
# require "crinja/loader/baked_file_loader"
#
# module MyBakedTemplateFileSystem
#   BakedFileSystem.load("templates", __DIR__)
# end
#
# env.loader = Crinja::BakedFileLoader.new(MyBakedTemplateFileSystem)
#
# # with choice loader:
# env.loader = Crinja::Loader::ChoiceLoader.new([
#   Crinja::Loader::FileSystemLoader.new("/path/to/user/templates"),
#   Crinja::Loader::BakedFileLoader.new(MyBakedTemplateFileSystem),
# ])
# ```
#
# See `examples/kilt/kilt.cr` for a practical example in conjunction with `Kilt`.
#
# A baked file system can also be used as a default
class Crinja::Loader::BakedFileLoader(T) < Crinja::Loader
  getter file_system : T

  def initialize(@file_system : T)
  end

  def get_source(env : Crinja, template : String) : {String, String}
    file = @file_system.get?(template)

    raise TemplateNotFoundError.new(template, self.class.to_s) unless file

    content = file.gets_to_end
    file.rewind
    return content, file.path
  end

  def list_templates
    @file_system.files.each
  end

  def to_s(io)
    io << "BakedFileSystemLoader("
    list_templates.each_with_index do |file, i|
      if i >= 4
        io << " ..."
        io << @file_system.files.size - 5
        break
      end
      io << ", " if i > 0
      io << file.name
    end
    io << ")"
  end
end
