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
end

module Crinja::Util
  def self.urlize(text, trim_url_limit, rel, target)
    text
  end
end
