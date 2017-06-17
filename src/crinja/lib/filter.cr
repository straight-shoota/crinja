# Variables can be modified by filters.
# Filters are separated from the variable by a pipe symbol (`|`) and may have optional arguments
# in parentheses. Multiple filters can be chained. The output of one filter is applied to the next.
#
# For example, `{{ name|striptags|title }}` will remove all HTML Tags from variable name and
# title-case the output (similar to `title(striptags(name))`).
#
# Filters that accept arguments have parentheses around the arguments, just like a function call.
#
# For example: `{{ listx|join(', ') }}` will join a list with commas (`list.join(", ")`).
#
# ## Builtin Filters
#
# The following filters are available in the default library:
#
# * `**[abs](http://jinja.pocoo.org/docs/2.9/templates/#abs)**()`
# * `**[attr](http://jinja.pocoo.org/docs/2.9/templates/#attr)**(<em>name</em>)`
# * `**[batch](http://jinja.pocoo.org/docs/2.9/templates/#batch)**(<em>linecount=2, fill_with=none</em>)`
# * `**[capitalize](http://jinja.pocoo.org/docs/2.9/templates/#capitalize)**()`
# * `**[center](http://jinja.pocoo.org/docs/2.9/templates/#center)**(<em>width=80</em>)`
# * `**[default](http://jinja.pocoo.org/docs/2.9/templates/#default)**(<em>default_value='', boolean=false</em>)`
# * `**[dictsort](http://jinja.pocoo.org/docs/2.9/templates/#dictsort)**(<em>case_sensitive=false, by='key'</em>)`
# * `**[escape](http://jinja.pocoo.org/docs/2.9/templates/#escape)**()`
# * `**[filesizeforma}](http://jinja.pocoo.org/docs/2.9/templates/#filesizeformat)**(<em>binary=false</em>)`
# * `**[first](http://jinja.pocoo.org/docs/2.9/templates/#first)**()`
# * `**[float](http://jinja.pocoo.org/docs/2.9/templates/#float)**(<em>default=0.0</em>)`
# * `**[forceescape](http://jinja.pocoo.org/docs/2.9/templates/#forceescape)**()`
# * `**[format](http://jinja.pocoo.org/docs/2.9/templates/#format)**()`
# * `**[groupby](http://jinja.pocoo.org/docs/2.9/templates/#groupby)**(<em>attribute</em>)`
# * `**[indent](http://jinja.pocoo.org/docs/2.9/templates/#indent)**(<em>width=4, indentfirst=false</em>)`
# * `**[int](http://jinja.pocoo.org/docs/2.9/templates/#int)**(<em>default=0, base=10</em>)`
# * `**[join](http://jinja.pocoo.org/docs/2.9/templates/#join)**(<em>separator='', attribute=none</em>)`
# * `**[last](http://jinja.pocoo.org/docs/2.9/templates/#last)**()`
# * `**[length](http://jinja.pocoo.org/docs/2.9/templates/#length)**()`
# * `**[list](http://jinja.pocoo.org/docs/2.9/templates/#list)**()`
# * `**[lower](http://jinja.pocoo.org/docs/2.9/templates/#lower)**()`
# * `**[map](http://jinja.pocoo.org/docs/2.9/templates/#map)**()`
# * `**[pprint](http://jinja.pocoo.org/docs/2.9/templates/#pprint)**(<em>verbose=false</em>)`
# * `**[random](http://jinja.pocoo.org/docs/2.9/templates/#random)**()`
# * `**[reject](http://jinja.pocoo.org/docs/2.9/templates/#reject)**()`
# * `**[rejectattr](http://jinja.pocoo.org/docs/2.9/templates/#rejectattr)**()`
# * `**[replace](http://jinja.pocoo.org/docs/2.9/templates/#replace)**(<em>old, new, count=none</em>)`
# * `**[reverse](http://jinja.pocoo.org/docs/2.9/templates/#reverse)**()`
# * `**[round](http://jinja.pocoo.org/docs/2.9/templates/#round)**(<em>precision=0, method='common', base=10</em>)`
# * `**[safe](http://jinja.pocoo.org/docs/2.9/templates/#safe)**()`
# * `**[select](http://jinja.pocoo.org/docs/2.9/templates/#select)**()`
# * `**[selectattr](http://jinja.pocoo.org/docs/2.9/templates/#selectattr)**()`
# * `**[slice](http://jinja.pocoo.org/docs/2.9/templates/#slice)**(<em>slices=2, fill_with=none</em>)`
# * `**[sort](http://jinja.pocoo.org/docs/2.9/templates/#sort)**(<em>reverse=false, case_sensitive=false, attribute=none</em>)`
# * `**[string](http://jinja.pocoo.org/docs/2.9/templates/#string)**()`
# * `**[striptags](http://jinja.pocoo.org/docs/2.9/templates/#striptags)**()`
# * `**[sum](http://jinja.pocoo.org/docs/2.9/templates/#sum)**(<em>attribute=none, start=0</em>)`
# * `**[title](http://jinja.pocoo.org/docs/2.9/templates/#title)**()`
# * `**[tojson](http://jinja.pocoo.org/docs/2.9/templates/#tojson)**(<em>indent=none</em>)`
# * `**[trim](http://jinja.pocoo.org/docs/2.9/templates/#trim)**()`
# * `**[truncate](http://jinja.pocoo.org/docs/2.9/templates/#truncate)**(<em>length=255, killwords=false, end='...', leeway=none</em>)`
# * `**[upper](http://jinja.pocoo.org/docs/2.9/templates/#upper)**()`
# * `**[urlencode](http://jinja.pocoo.org/docs/2.9/templates/#urlencode)**()`
# * `**[urlize](http://jinja.pocoo.org/docs/2.9/templates/#urlize)**(<em>trim_url_limit=none, nofollow=false, target=none, rel=none</em>)`
# * `**[wordcount](http://jinja.pocoo.org/docs/2.9/templates/#wordcount)**()`
# * `**[wordwrap](http://jinja.pocoo.org/docs/2.9/templates/#wordwrap)**(<em>width=79, break_long_words=true, wrapstring=none</em>)`
# * `**[xmlattr](http://jinja.pocoo.org/docs/2.9/templates/#xmlattr)**(<em>autoescape=true</em>)`
module Crinja::Filter
  class Library < FeatureLibrary(Callable)
  end
end

require "./filter/*"
