require "http/server"
require "colorize"
require "benchmark"
require "../../src/crinja.cr"
require "./source_renderer.cr"

host = "0.0.0.0"
port = ARGV[0]?.try(&.to_i) || 7645

crinja = Crinja::Environment.new(loader: Crinja::Loader::FileSystemLoader.new("pages"))

logger = Logger.new(STDERR)

source_renderer = Crinja::Server::SourceRenderer.new(crinja)

handlers = [HTTP::ErrorHandler.new, HTTP::LogHandler.new, HTTP::StaticFileHandler.new("public")]
server = HTTP::Server.new(host, port, handlers) do |context|
  path = context.request.path

  show_source = path[0..7] == "/source/"
  path = path[7..-1] if show_source

  if path[-1] == '/'
    path += "index.html"
  end

  begin
    template = uninitialized Crinja::Template
    time_to_parse = Benchmark.measure "parse #{path}" do
      template = crinja.get_template(path)
    end
    puts "Time to parse #{path}: #{time_to_parse.colorize(:yellow)}"

    context.response.content_type = "text/html"
    if show_source
      source_renderer.render(context.response, template)
    else
      vars = {
        "crinja" => {
          "version" => Crinja::VERSION,
        },
      }
      time_to_render = Benchmark.measure "render #{path}" do
        template.render(context.response, vars)
      end
      puts "Time to render #{path}: #{time_to_render.colorize(:yellow)}"
    end
  rescue e : Crinja::TemplateNotFoundError
    logger.warn e.message
    context.response.respond_with_error "File Not Found", 404
  end
end

server.bind

url = "http://#{host}:#{port}".colorize(:cyan)
puts "Crinja example server is listening on #{url}"

server.listen
