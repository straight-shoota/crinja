require "benchmark"
require "../../src/crinja.cr"

env = Crinja::Environment.new

env.filters[:dateformat] = Crinja.filter { target.as_time.to_s("%Y-%m-%d") }
env.loader = Crinja::Loader::FileSystemLoader.new(File.join(FileUtils.pwd, "crinja"))

time_to_parse = Benchmark.measure "parse crinja" do
  env.get_template("index.html")
end
crinja_template = env.get_template("index.html") # uses cache

users = ["John Doe", "Jane Doe", "Peter Somewhat"].map { |n| User.new(n) }
articles = (0..20).map { |i| Article.new(i, users.sample) }

private class Article
  include Crinja::PyObject
  getter id, href, title, user, body, pub_date, published
  getattr

  def initialize(@id : Int32, @user : User)
    @href = "/article/#{@id}"
    @title = "Lorem Ipsum #{id}"
    @body = "Lorem Ipsum dolor... #{id}"
    @pub_date = Time.epoch(Random.new.rand((10 ** 9)..(2 * 10 ** 9)))
    @published = true
  end
end

private class User
  include Crinja::PyObject
  getter username, href
  getattr

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

rendered = ""
time_to_render = Benchmark.measure "render crinja" do
  rendered = crinja_template.render(context)
end

File.write(File.join(FileUtils.pwd, "rendered_crinja.html"), rendered)

puts "parsed in #{time_to_parse}"
puts "rendered in #{time_to_render}"
