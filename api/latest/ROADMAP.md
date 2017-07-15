# Roadmap

* `Crinja::Template.@env`: duplicate environment for this template to avoid spilling to global scope, but keep current scope even if render method has finished? `@env = @env.dup`

# Possible additions
* Extension **Loop Controls**: `break` and `continue` tags
* Extension **I18N**: `pluralize` and `trans` tags
* Extension **Expression Statement**: `do` tag
