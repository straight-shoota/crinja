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
