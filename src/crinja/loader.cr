require "file_utils"

module Crinja
  # Base class for all loaders.
  abstract class Loader
    # Get the template source, filename and reload helper for a template.
    # It's passed the environment and template name and has to return a
    # tuple in the form ``{source, filename, uptodate}`` or raise a
    # `TemplateNotFoundError` if it can't locate the template.
    # The source part of the returned tuple must be the source of the
    # template as string. The filename should be the name of the file on
    # the filesystem if it was loaded from there, otherwise `nil`.
    # The filename is used for the tracebacks if no loader extension is used.
    abstract def get_source(env : Environment, template : String) : {String, String}

    # Iterates over all templates. If the loader does not support that
    # it should raise a `TypeError` which is the default behavior.
    def list_templates : Iterable(String)
      raise TypeError.new("this loader cannot iterate over all templates")
    end

    def load(env, name)
      source, file_name = get_source(env, name)

      env.cache.fetch(env, name, file_name, source) do
        Template.new(source, env, name, file_name)
      end
    end

    # Split a path into segments and perform a sanity check. If it detects
    # '..' in the path it will raise a `TemplateNotFoundError`.
    private def split_template_path(template)
      template.split('/').select do |piece|
        if piece.includes?(File::SEPARATOR) || piece == ".."
          raise TemplateNotFoundError.new(template)
        end

        piece && piece != '.'
      end
    end

    # Loads templates from the file system.  This loader can find templates
    # in folders on the file system and is the preferred way to load them.
    # The loader takes the path to the templates as string, or if multiple
    # locations are wanted a list of them which is then looked up in the
    # given order.
    class FileSystemLoader < Loader
      property searchpaths : Array(String)
      getter encoding : String?

      # The default encoding is `nil` which can be changed
      # by setting the `encoding` parameter to something else.
      # To follow symbolic links, set the *followlinks* parameter to `true`
      def initialize(@searchpaths, @encoding = nil, @followlinks = false)
      end

      # ditto
      def initialize(searchpath : String = FileUtils.pwd, encoding = nil, followlinks = false)
        initialize([searchpath])
      end

      def to_s(io)
        io << "FileSystemLoader("
        io << searchpaths.join(":")
        io << ")"
      end

      def get_source(env : Environment, template : String)
        pieces = split_template_path(template)
        searchpaths.each do |searchpath|
          file_name = File.join(searchpath, File.join(pieces))

          if File.exists?(file_name)
            begin
              source = File.read(file_name, encoding: @encoding)
              return {source, file_name}
            rescue e : IO::Error | Errno
              raise TemplateNotFoundError.new(template, self, e.message, e)
            end
          end
        end

        raise TemplateNotFoundError.new(template, self)
      end
    end

    # Load templates from a hash in memory.
    class HashLoader < Loader
      property data : Hash(String, String)

      def initialize(@data)
      end

      delegate :[], :[]=, to: data

      def get_source(env : Environment, template : String)
        raise TemplateNotFoundError.new(template, self) unless data.has_key?(template)

        {data[template], nil}
      end

      def list_templates
        data.keys
      end
    end

    # Load templates from other loaders based on prefix.
    class PrefixLoader < Loader
      property mapping : Hash(String, Loader)

      # The prefix is delimited from the template by a slash per
      # default, which can be changed by setting the *delimiter* argument.
      #  loader = PrefixLoader.new({
      #      "app1" =>     FileSystemLoader("app1"),
      #      "app2" =>     FileSystemLoader("../otherapp")
      #  })
      # By loading `app1/index.html` the file path `app1/index.html` is loaded
      # by loading `app2/index.html` the file path `../otherapp/index.html`.
      def initialize(@mapping, @delimiter = "/")
      end

      delegate :[], :[]=, to: mapping

      def get_source(env : Environment, template : String)
        prefix, slash, rest = template.partition(@delimiter)

        if loader = mapping[prefix]?
          return loader.get_source(env, template)
        end

        raise TemplateNotFoundError.new(template, self, "no mapping for prefix #{prefix}")
      end
    end

    # Load templates from first matching loader. If a template could not be found
    # by one loader the next one is tried.
    # ```
    # loader = ChoiceLoader.new([
    #   FileSystemLoader.new("/path/to/user/templates"),
    #   FileSystemLoader.new("/path/to/system/templates"),
    # ])
    # ```
    # This is useful if you want to allow users to override builtin templates
    # from a different location.
    class ChoiceLoader < Loader
      property choices : Array(Loader)

      def initialize(@choices)
      end

      delegate :[], :<<, to: choices

      def get_source(env : Environment, template : String)
        choices.each do |loader|
          begin
            return loader.get_source(env, template)
          rescue TemplateNotFoundError
          end
        end

        raise TemplateNotFoundError.new(template, self)
      end

      def list_templates
        loaders.map(&.list_templates).flatten.uniq.sort
      end
    end
  end
end
