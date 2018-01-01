# Beside filters, there are also so-called “tests” available.
# Tests can be used to test a variable against a common expression. To test a variable or expression,
# you add `is` plus the name of the test after the variable. For example, to find out if a variable
# is defined, you can do `name is defined`, which will then return true or false depending on
# whether name is defined in the current template context.
#
# Tests can accept arguments, too. If the test only takes one argument, you can leave out the
# parentheses. For example, the following two expressions do the same thing:
#
# ```crinja
# {% if loop.index is divisibleby 3 %}
# {% if loop.index is divisibleby(3) %}
# ```
#
# ## Builtin Tests
#
# The following tests are available in the default library:
#
# * `**[callable](http://jinja.pocoo.org/docs/2.9/templates/#callable)**(<em></em>)`
# * `**[defined](http://jinja.pocoo.org/docs/2.9/templates/#defined)**(<em></em>)`
# * `**[divisibleby](http://jinja.pocoo.org/docs/2.9/templates/#divisibleby)**(<em>num</em>)`
# * `**[equalto](http://jinja.pocoo.org/docs/2.9/templates/#equalto)**(<em>other</em>)`
# * `**[escaped](http://jinja.pocoo.org/docs/2.9/templates/#escaped)**(<em></em>)`
# * `**[even](http://jinja.pocoo.org/docs/2.9/templates/#even)**(<em></em>)`
# * `**[greaterthan](http://jinja.pocoo.org/docs/2.9/templates/#greaterthan)**(<em>other=0</em>)`
# * `**[in](http://jinja.pocoo.org/docs/2.9/templates/#in)**(<em>seq=[]</em>)`
# * `**[iterable](http://jinja.pocoo.org/docs/2.9/templates/#iterable)**(<em></em>)`
# * `**[lessthan](http://jinja.pocoo.org/docs/2.9/templates/#lessthan)**(<em>other=0</em>)`
# * `**[lower](http://jinja.pocoo.org/docs/2.9/templates/#lower)**(<em></em>)`
# * `**[mapping](http://jinja.pocoo.org/docs/2.9/templates/#mapping)**(<em></em>)`
# * `**[nil](http://jinja.pocoo.org/docs/2.9/templates/#nil)**(<em></em>)`
# * `**[none](http://jinja.pocoo.org/docs/2.9/templates/#none)**(<em></em>)`
# * `**[number](http://jinja.pocoo.org/docs/2.9/templates/#number)**(<em></em>)`
# * `**[odd](http://jinja.pocoo.org/docs/2.9/templates/#odd)**(<em></em>)`
# * `**[sameas](http://jinja.pocoo.org/docs/2.9/templates/#sameas)**(<em>other</em>)`
# * `**[sequence](http://jinja.pocoo.org/docs/2.9/templates/#sequence)**(<em></em>)`
# * `**[string](http://jinja.pocoo.org/docs/2.9/templates/#string)**(<em></em>)`
# * `**[undefined](http://jinja.pocoo.org/docs/2.9/templates/#undefined)**(<em></em>)`
# * `**[upper](http://jinja.pocoo.org/docs/2.9/templates/#upper)**(<em></em>)`
module Crinja::Test
  class Library < FeatureLibrary(Callable)
  end
end

require "./test/*"
