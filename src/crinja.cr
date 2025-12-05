# This class represents the core component of the Crinja template engine.
#
# It contains the *runtime environment* including configuration, global variables
# as well as loading and rendering templates.
#
# Instances of this class may be modified if they are not shared and if no template
# was loaded so far. Modifications on environments after the first template was
# loaded will lead to surprising effects and undefined behavior.
#
# It also contains macros to easily define custom template features such as filters, tests
# and functions.
class Crinja
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  # Render Crinja template *template* to a String.
  #
  # Variables for the template can be assigned as parameter *variables*.
  #
  # This uses default *loader* and *config* unless these are provided as
  # optional parameters.
  #
  # A new `Crinja` instance will be created for each invocation and it will
  # parse the *template*. To parse the same template once and invoke it multiple
  # times, it needs to be created directly (using `Crinja#from_string` or
  # `Template.new`) and stored in a variable.
  def self.render(template, variables = nil, loader = Loader.new, config = Config.new) : String
    String.build do |io|
      render io, template, variables, loader, config
    end
  end

  # Render Crinja template *template* to an `IO` *io*.
  #
  # Variables for the template can be assigned as parameter *variables*.
  #
  # This uses default *loader* and *config* unless these are provided as
  # optional parameters.
  #
  # A new `Crinja` instance will be created for each invocation and it will
  # parse the *template*. To parse the same template once and invoke it multiple
  # times, it needs to be created directly (using `Crinja#from_string` or
  # `Template.new`) and stored in a variable.
  def self.render(io : IO, template, variables = nil, loader = Loader.new, config = Config.new)
    env = Crinja.new(config: config, loader: loader)

    env.from_string(template.to_s).render(io, variables)
  end
end

require "./util/*"
require "./config"
require "./environment"
require "./error"
require "./loader"
require "./template"
require "./parser/*"
require "./runtime/*"
require "./lib/feature_library"
require "./lib/tag"
require "./lib/function"
require "./lib/filter"
require "./lib/operator"
require "./lib/test"
require "./visitor/*"
