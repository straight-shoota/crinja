require "uri"
require "html"
require "../../util/json_builder"

module Crinja::Filter
  Crinja.filter({trim_url_limit: nil, nofollow: false, target: nil, rel: nil}, :urlize) do
    rel = arguments[:rel].to_s.split(' ')

    rel << "nofollow" if arguments[:nofollow].truthy?
    rel |= env.policies.fetch("urlize.rel", "noopener").to_s.split(' ')
    rel = rel.reject(&.empty?).to_set

    target_attr = arguments.fetch(:target) { env.policies.fetch("urlize.target", nil) }.raw.as(String?)
    trim_url_limit = arguments[:trim_url_limit].raw.as(Int32?)

    Crinja::Util.urlize(target.to_s, trim_url_limit, rel, target_attr)
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

    SafeString.escape do |io|
      JsonBuilder.to_json(io, raw, indent)
    end
  end

  Crinja.filter({autoescape: true}, :xmlattr) do
    string = SafeString.build do |io|
      target.as_h.each_with_index do |(key, value), i|
        next if value.nil? || value.is_a?(Undefined)

        io << sprintf %( %s="%s"), HTML.escape(key.to_s), HTML.escape(value.to_s)
      end
    end

    if string.size > 0 && !arguments[:autoescape].truthy?
      string = string[1..-1]
    end

    string
  end
end

module Crinja::Util
  # https://github.com/tenderlove/rails_autolink/blob/master/lib/rails_autolink/helpers.rb
  AUTO_LINK_RE = %r{
              (?: ([0-9A-Za-z+.:-]+:)// | www\. )
              [^\s<]+
            }x

  def self.urlize(text, trim_url_limit, rel, target)
    rel_attr = ""
    rel_attr = %( rel="%s") % HTML.escape(rel.join(' ')) unless rel.empty?

    target_attr = ""
    target_attr = %( target="%s") % HTML.escape(target) unless target.nil? || target.empty?

    SafeString.build do |io|
      text.each_line do |line|
        io << line.gsub(AUTO_LINK_RE) do
          scheme, all = $1, $~
          url = all[0]
          display = url
          unless trim_url_limit.nil? || display.size < trim_url_limit
            display = display[0..(trim_url_limit - 3)] + "..."
          end
          %(<a href="#{url}"#{rel_attr}#{target_attr}>#{display}</a>)
        end
      end
    end
  end
end
