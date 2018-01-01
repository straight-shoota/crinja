# This is the main namespace for Crinja template engine.
# It contains macros to easily define custom template features such as filters, tests
# and functions.
#
# The most important class for using the Crinja API is `Crinja::Environment`.
module Crinja
  # Tries to cast any value to `Crinja::Type`.
  def self.cast_type(value)
    Bindings.cast_value(value)
  end

  # Tries to cast any value to `Dictionary`.
  def self.cast_hash(value) : Dictionary
    Bindings.cast_hash(value)
  end
end

require "./util/*"
require "./config"
require "./environment"
require "./error"
require "./loader"
require "./template"
require "./version"
require "./parser/*"
require "./runtime/*"
require "./lib/feature_library"
require "./lib/tag"
require "./lib/function"
require "./lib/filter"
require "./lib/operator"
require "./lib/test"
require "./visitor/*"
