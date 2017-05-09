require "file_utils"

module Crinja
  abstract class Loader
    abstract def get_source(env : Environment, template : String)

    class FileSystemLoader < Loader
      property searchpaths : Array(String)

      def initialize(searchpath : String = FileUtils.pwd)
        initialize([searchpath])
      end

      def initialize(@searchpaths)
      end

      def get_source(env : Environment, template : String)
        searchpaths.each do |searchpath|
          path = File.join(searchpath, template)

          return {File.read(path), path} if File.exists?(path)
        end

        raise TemplateNotFoundError.new(template, self)
      end
    end

    class HashLoader < Loader
      property data : Hash(String, String)

      def initialize(@data)
      end

      def get_source(env : Environment, template : String)
        raise TemplateNotFoundError.new(template, self) unless data.has_key?(template)
        {data[template], nil}
      end
    end

    class PrefixLoader < Loader
      property prefixes : Hash(String, Loader)

      def initialize(@prefixes)
      end

      def get_source(env : Environment, template : String)
        prefix, slash, rest = template.partition("/")

        raise TemplateNotFoundError.new(template, self) unless prefixes.has_key?(prefix)
        prefixes[prefix].get_source(env, template)
      end
    end

    class ChoiceLoader < Loader
      property choices : Array(Loader)

      def initialize(@choices)
      end

      def get_source(env : Environment, template : String)
        choices.each do |loader|
          begin
            return loader.get_source(env, template)
          rescue TemplateNotFoundError
          end
        end

        raise TemplateNotFoundError.new(template, self)
      end
    end
  end
end
