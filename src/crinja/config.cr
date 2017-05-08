module Crinja
  class Config
    property autoescape : AutoescapeConfig = AutoescapeConfig.new
    delegate autoescape?, to: autoescape
    def autoescape=(flag : Bool)
      if flag
        autoescape = AutoescapeConfig::DISABLED
      else
        autoescape = AutoescapeConfig::ENABLED
      end
    end

    property keep_trailing_newline : Bool = false
    property trim_blocks : Bool = false
    property lstrip_blocks : Bool = false

    class AutoescapeConfig
      getter enabled_extensions : Array(String) = [] of String
      getter disabled_extensions : Array(String) = [] of String
      property default_for_string : Bool
      property default : Bool

      DISABLED = AutoescapeConfig.new(enabled_extensions: [] of String, default_for_string: false, default: false)
      ENABLED = AutoescapeConfig.new(disabled_extensions: [] of String, default_for_string: true, default: true)

      def initialize(
                     enabled_extensions = ["html", "htm", "xml"],
                     disabled_extensions = [] of String,
                     @default_for_string = true,
                     @default = true)
        self.enabled_extensions = enabled_extensions
        self.disabled_extensions = disabled_extensions
      end

      def enabled_extensions=(extensions : Array(String))
        @enabled_extensions = extensions.map(&.downcase)
      end

      def disabled_extensions=(extensions : Array(String))
        @disabled_extensions = extensions.map(&.downcase)
      end

      def autoescape?(filename : String?)
        if filename.nil? || filename.size == 0
          default_for_string
        elsif match_extension?(enabled_extensions, filename)
          true
        elsif match_extension?(disabled_extensions, filename)
          false
        else
          default
        end
      end

      def match_extension?(extensions : Array(String), filename : String)
        filename = filename.downcase
        extname = File.extname(filename)
        if [".jinja", ".j2"].includes?(extname)
          extname = File.extname(filename[0..(-extname.size - 1)])
        end
        extensions.includes?(extname[1..-1])
      end
    end
  end
end
