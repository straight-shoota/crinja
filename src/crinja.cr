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

  # Tries to cast any value to `Crinja::Type`.
  def self.cast_type(value)
    Bindings.cast_value(value)
  end

  # Tries to cast any hash-like value to `Dictionary`.
  def self.cast_dictionary(value) : Dictionary
    Bindings.cast_dictionary(value)
  end

  # Tries to cast any hash-like value to `Variables`.
  def self.cast_variables(value) : Variables
    Bindings.cast_variables(value)
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
