module Crinja
  class Config
    # property autoescape = {
    #  enabled_extension: ["html", "htm", "xml"],
    #  disabled_extensions: [],
    #  default_for_string: true,
    #  default: true
    # }
    property keep_trailing_newline : Bool = false
    property trim_blocks : Bool = false
    property lstrip_blocks : Bool = false
  end
end
