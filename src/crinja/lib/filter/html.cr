require "uri"
require "../../util/json_builder"

module Crinja::Filter
  Crinja.filter({trim_url_limit: nil, nofollow: false, target: nil, rel: nil}, :urlize) do
    rel = arguments[:rel].to_s.split(' ').to_set

    rel << "nofollow" if arguments[:nofollow].truthy?
    rel &= env.policies.fetch("urlize.rel", "noopener").to_s.split(' ').to_set

    target_attr = arguments.fetch(:target) { env.policies.fetch("urlize.target", "_blank") }.to_s
    trim_url_limit = arguments[:trim_url_limit].raw.as(Int32?)

    rv = Crinja::Util.urlize(target.to_s, trim_url_limit, rel: rel, target: target_attr)

    rv
  end

  Crinja.filter(:urlencode) do
    if target.iterable?
      target.map do |item|
        if item.iterable? && item.size == 2
          [URI.escape(item[0].to_s), "=", URI.escape(item[1].to_s)].join.as(Type)
        else
          URI.escape(item.to_s).as(Type)
        end
      end.join("&")
    else
      URI.escape(target.to_s)
    end
  end

  # TODO: This is still a draft implementation.
  # `responds_to?(:to_json)` is true for every object, because to_json.cr adds the wrappers everywhere.
  Crinja.filter({indent: nil}, :tojson) do
    raw = target.raw

    indent = arguments.fetch(:indent, 0).to_i

    json = JsonBuilder.to_json(raw, indent)

    string = SafeString.escape(json)

    string
  end

  Crinja.filter({autoescape: true}, :xmlattr) do
    string = SafeString.build do |io|
      target.as_h.each_with_index do |(key, value), i|
        next if value.nil? || value.is_a?(Undefined)

        io << sprintf %( %s="%s"), SafeString.escaped(key), SafeString.escaped(value)
      end
    end

    if string.size > 0 && !arguments[:autoescape].truthy?
      string = string[1..-1]
    end

    string
  end
end

module Crinja::Util
  def self.urlize(text, trim_url_limit, rel, target)
    text
  end
end
