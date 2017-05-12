# Caching for parsed `Template` objects.
abstract class Crinja::TemplateCache
  # Try to fetch template from cache. If not found, this method yields and in the attached block
  # the template should be initialized. Implementing classes should store the value from the
  # yield and return it to the caller.
  abstract def fetch(env, name, file_name, source, &block)

  # This cache does not cache anything.
  class NoCache < TemplateCache
    def fetch(env, name, file_name, source)
      yield
    end
  end

  # This cache stores `Template` objects in a `Hash`.
  class InMemory < TemplateCache
    @cache = Hash(Tuple(Environment, String, String?, String), Template).new

    def fetch(env, name, file_name, source)
      id = {env, name, file_name, source}

      @cache.fetch(id) do
        @cache[id] = yield
      end
    end
  end
end
