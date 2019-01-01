class Crinja
  def self.liquid_support(config = Config.new) : Crinja
    config.liquid_compatibility_mode = true
    #config.undefined_members = true

    crinja = new(config)

    crinja.tags << Tag::Unless.new
    crinja.tags << Tag::Comment.new
    crinja.tags.aliases["assign"] = "set"
    crinja.tags.aliases["elsif"] = "elif"

    crinja.filters.aliases["size"] = "length"
    crinja.filters.aliases["strip_html"] = "striptags"
    crinja.filters.aliases["remove"] = "replace"
    crinja.filters["escape_once"] = Crinja.filter do
      Value.new SafeString.new(HTML.escape(target.as_s.to_s))
    end
    # TODO: Implement
    crinja.filters["truncatewords"] = Crinja.filter do
      Value.new target.as_s
    end

    crinja
  end

  class Tag::Comment < Tag
    name "comment", "endcomment"

    private def interpret(io : IO, renderer : Crinja::Renderer, tag_node : TagNode)
    end
  end
end
