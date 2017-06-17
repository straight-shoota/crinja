# Roadmap

* implement all standard filters
* sandbox environment
* `Crinja::Template.@env`: duplicate environment for this template to avoid spilling to global scope, but keep current scope even if render method has finished? `@env = @env.dup`
