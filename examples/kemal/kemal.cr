require "kemal"
require "../../src/crinja.cr"

crinja = Crinja::Environment.new do |crinja|
  crinja.loader = Crinja::Loader::FileSystemLoader.new("pages")
end

logger = Logger.new(STDERR)

get "/source/*" do |env|
  path = env.request.path
  path = path[7..-1]
  puts "path=#{path}"
  if path[-1] == '/'
    path += "index.html"
  end
  begin
    template = crinja.get_template(path)
    String.build do |io|
      io << %(<link href="/source.css" rel="stylesheet">)
      io << "Crinja template code for #{path}:"
      io << "<pre>"
      Crinja::Visitor::HTML.new(io).visit(template)
      io << "</pre>"
    end
  rescue e : Crinja::TemplateNotFoundError
    logger.warn e.message
    env.response.respond_with_error "File Not Found", 404
  end
end

get "/*" do |env|
  path = env.request.path
  if path[-1] == '/'
    path += "index.html"
  end

  begin
    template = crinja.get_template(path)
    vars = {
      "crinja" => {
        "version" => Crinja::VERSION,
      },
    }
    template.render(vars)
  rescue e : Crinja::TemplateNotFoundError
    logger.warn e.message
    env.response.respond_with_error "File Not Found", 404
  end
end

Kemal.run
