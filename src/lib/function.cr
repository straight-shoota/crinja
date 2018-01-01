# Global functions are available everywhere.
#
# ## Builtin functions
#
# The following functions are available in the default library:
#
# * `**[cycler](http://jinja.pocoo.org/docs/2.9/templates/#cycler)**(<em></em>)`
# * `**[debug](http://jinja.pocoo.org/docs/2.9/templates/#debug)**(<em></em>)`
# * `**[dict](http://jinja.pocoo.org/docs/2.9/templates/#dict)**(<em></em>)`
# * `**[joiner](http://jinja.pocoo.org/docs/2.9/templates/#joiner)**(<em>sep=', '</em>)`
# * `**[range](http://jinja.pocoo.org/docs/2.9/templates/#range)**(<em>start=0, stop=0, step=1</em>)`
# * `**[super](http://jinja.pocoo.org/docs/2.9/templates/#super)**(<em></em>)`
module Crinja::Function
  class Library < FeatureLibrary(Callable)
  end
end

require "./function/*"
