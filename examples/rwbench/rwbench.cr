require "benchmark"
require "crinja"

env = Crinja.new

env.filters[:dateformat] = Crinja.filter { target.as_time.to_s("%Y-%m-%d") }
env.loader = Crinja::Loader::FileSystemLoader.new(File.join(FileUtils.pwd, "crinja"))

users = ["John Doe", "Jane Doe", "Peter Somewhat"].map { |n| User.new(n) }
articles = (0..20).map { |i| Article.new(i, users.sample) }

@[Crinja::Attributes]
private class Article
  include Crinja::Object::Auto
  getter id, href, title, user, body, pub_date, published

  def initialize(@id : Int32, @user : User)
    @href = "/article/#{@id}"
    @title = "Lorem Ipsum #{id}"
    @body = "Lorem Ipsum dolor... #{id}"
    @pub_date = Time.epoch(Random.new.rand((10 ** 9)..(2 * 10 ** 9)))
    @published = true
  end
end

@[Crinja::Attributes]
private class User
  include Crinja::Object::Auto
  getter username, href

  def initialize(@username : String)
    @href = "/user/#{username}"
  end
end

context = {
  "users"           => users,
  "articles"        => articles,
  "page_navigation" => [
    ["index", "Index"],
    ["about", "About"],
    ["foo?bar=1", "Foo with Bar"],
    ["foo?bar=2&s=x", "Foo with X"],
    ["blah", "Blub Blah"],
    ["hehe", "Haha"],
  ] * 5,
}

env.get_template("index.html")
crinja_template = env.get_template("index.html") # uses cache
rendered = crinja_template.render(context)
File.write(File.join(FileUtils.pwd, "crinja.rendered.html"), rendered)

env.cache = Crinja::TemplateCache::NoCache.new
Benchmark.ips do |x|
  x.report("parse crinja") { env.get_template("index.html") }
  x.report("crinja render") { crinja_template.render(context) }
end
