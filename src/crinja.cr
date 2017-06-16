# This is the main namespace for Crinja template engine.
# It contains macros to easily define custom template features such as filters, tests
# and functions.
#
# The most important class for using the Crinja API is `Crinja::Environment`.
module Crinja
end

require "./crinja/util/*"
require "./crinja/config"
require "./crinja/context"
require "./crinja/environment"
require "./crinja/error"
require "./crinja/loader"
require "./crinja/template"
require "./crinja/value"
require "./crinja/version"
require "./crinja/parser/*"
require "./crinja/interpreter/*"
require "./crinja/lib/*"
require "./crinja/visitor/*"
