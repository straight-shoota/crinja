module Crinja
  class Config
    property autoescape : AutoescapeConfig = AutoescapeConfig.new
    delegate autoescape?, to: autoescape

    property keep_trailing_newline : Bool = false
    property trim_blocks : Bool = false
    property lstrip_blocks : Bool = false

    class AutoescapeConfig
      property enabled_extensions : Array(String)
      property disabled_extensions : Array(String)
      property default_for_string : Bool
      property default : Bool

      DISABLED = AutoescapeConfig.new(enabled_extensions: [] of String, default_for_string: false, default: false)

      def initialize(
          @enabled_extensions = ["html", "htm", "xml"],
          @disabled_extensions = [] of String,
          @default_for_string = true,
          @default = true
        )
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
        extname = File.extname(filename)
        if [".jinja", ".j2"].includes?(extname)
          extname = File.extname(filename[0..(-extname.size() -1)])
        end
        extensions.includes?(extname[1..-1])
      end
    end
  end
end
