module Crinja
  # This class holds configuration values for a Crinja environment.
  class Config
    # This setting configures autoescape behaviour. See `AutoescapeConfig` for details.
    #
    # When set to a boolean value, `false` deactivates any autoescape and `true` activates autoescape for any template.
    # NOTE: The default configuration of Crinja differs from that of Jinja 2.9, that autoescape is activated by default for XML and HTML files. This will most likely be changed by Jinja2 in the future, too.
    property autoescape : AutoescapeConfig

    delegate autoescape?, to: autoescape

    def autoescape=(flag : Bool)
      if flag
        autoescape = AutoescapeConfig::DISABLED
      else
        autoescape = AutoescapeConfig::ENABLED
      end
    end

    # Preserve the trailing newline when rendering templates.
    # If set to `false`, a single newline, if present, willl be stripped from the end of the template.
    property keep_trailing_newline : Bool = false
    # If this is set to `true``, the first newline after a block is removed.
    # This only applies to blocks, not expression tags.
    property trim_blocks : Bool = false
    # If this is set to `true`, leading spaces and tabs are stripped from the start of a line to a block.
    property lstrip_blocks : Bool = false

    # Initializes a configuration object.
    def initialize(
                   @autoescape = AutoescapeConfig.new,
                   @keep_trailing_newline = false,
                   @trim_blocks = false,
                   @lstrip_blocks = false)
    end

    # This class holds configuration values for autoescape config.
    #
    # It accepts the same settings as `[select_autoescape](http://jinja.pocoo.org/docs/2.9/api/#jinja2.select_autoescape)` in Jinja 2.9.
    # It intelligently sets the initial value of autoescaping based on the filename of the template.
    class AutoescapeConfig
      # List of filename extensions that autoescape should be enabled for.
      getter enabled_extensions : Array(String) = [] of String
      # List of filename extensions that autoescape should be disabled for.
      getter disabled_extensions : Array(String) = [] of String
      # Determines autoescape default value for templates loaded from a string (without a filename).
      property default_for_string : Bool
      # If nothing matches, this will be the default autoescape value.
      property default : Bool

      # Configuration settings where autoescape is deactivated by default for any kind of template.
      DISABLED = AutoescapeConfig.new(enabled_extensions: [] of String, default_for_string: false, default: false)
      # Configuration settings where autoescape is activated by default for any kind of template.
      ENABLED = AutoescapeConfig.new(disabled_extensions: [] of String, default_for_string: true, default: true)

      # Initializes the default autoescape configuration.
      def initialize(
                     enabled_extensions = ["html", "htm", "xml"],
                     disabled_extensions = [] of String,
                     @default_for_string = false,
                     @default = false)
        self.enabled_extensions = enabled_extensions
        self.disabled_extensions = disabled_extensions
      end

      def enabled_extensions=(extensions : Array(String))
        @enabled_extensions = extensions.map(&.downcase)
      end

      def disabled_extensions=(extensions : Array(String))
        @disabled_extensions = extensions.map(&.downcase)
      end

      # Determines if a template with *filename* should have autoescape enabled or not.
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

      # :nodoc:
      def match_extension?(extensions : Array(String), filename : String)
        filename = filename.downcase
        extname = File.extname(filename)
        if {".jinja", ".j2"}.includes?(extname)
          extname = File.extname(filename[0..(-extname.size - 1)])
        end
        extensions.includes?(extname[1..-1])
      end
    end
  end
end
