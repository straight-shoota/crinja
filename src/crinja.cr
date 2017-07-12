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

  # Tries to cast any value to `Hash(Crinja::Type => Crinja::Type)`.
  def self.cast_hash(value)
    Bindings.cast_hash(value)
  end
end

require "./crinja/util/*"
require "./crinja/config"
require "./crinja/environment"
require "./crinja/error"
require "./crinja/loader"
require "./crinja/template"
require "./crinja/version"
require "./crinja/parser/*"
require "./crinja/runtime/*"
require "./crinja/lib/feature_library"
require "./crinja/lib/tag"
require "./crinja/lib/function"
require "./crinja/lib/filter"
require "./crinja/lib/operator"
require "./crinja/lib/test"
require "./crinja/visitor/*"
