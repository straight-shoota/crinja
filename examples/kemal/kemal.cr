require "kemal"
require "crinja"

crinja = Crinja.new(loader: Crinja::Loader::FileSystemLoader.new("pages"))

logger = ::Log.for("crinja.examples.kemal")

source_renderer = Crinja::Server::SourceRenderer.new(crinja)

get "/source/*" do |env|
  path = env.request.path
  path = path[7..-1]
  puts "path=#{path}"
  if path[-1] == '/'
    path += "index.html"
  end

  begin
    source_renderer.render(crinja.get_template(path))
  rescue exc : Crinja::TemplateNotFoundError
    logger.warn { exc.message }
    env.response.respond_with_status :not_found
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
  rescue exc : Crinja::TemplateNotFoundError
    logger.warn { exc.message }
    env.response.respond_with_status :not_found
  end
end

class Crinja::Server::SourceRenderer
  def initialize(@env : Crinja)
  end

  def render(template)
    String.build do |io|
      io << %(<link href="/source.css" rel="stylesheet">)
      io << "Crinja template code for #{template.filename}:"
      io << "<pre>"
      Crinja::Visitor::HTML.new(io).visit(template)
      io << "</pre>"
    end
  end
end

Kemal.run
