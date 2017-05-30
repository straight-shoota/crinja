require "http/server"
require "../../src/crinja.cr"

crinja = Crinja::Environment.new do |crinja|
  crinja.loader = Crinja::Loader::FileSystemLoader.new("pages")
end

logger = Logger.new(STDERR)

host = "0.0.0.0"
port = 7645
handlers = [HTTP::ErrorHandler.new, HTTP::LogHandler.new]
server = HTTP::Server.new(host, port, handlers) do |context|
  path = context.request.path
  if path[-1] == '/'
    path += "index.html"
  end
  begin
    template = crinja.get_template(path)
    context.response.content_type = "text/html"
    vars = {
      "crinja" => {
        "version" => Crinja::VERSION,
      },
    }
    context.response.print template.render(vars)
  rescue e : Crinja::TemplateNotFoundError
    logger.warn e.message
    context.response.respond_with_error "File Not Found", 404
  end
end

puts "Listening on http://#{host}:#{port}"
server.listen
