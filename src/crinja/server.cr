require "http/server"
require "colorize"
require "benchmark"

class Crinja::Server
  DEFAULT_HOST = "0.0.0.0"
  DEFAULT_PORT = 7645

  property host : String = DEFAULT_HOST
  property port : Int32 = DEFAULT_PORT
  property template_dir : String = "pages"
  property public_dir : String = "public"
  property logger : Logger = Logger.new(STDERR)

  getter env : Environment
  getter! server : HTTP::Server
  getter! loader : Crinja::Loader

  include Crinja::PyObject
  getattr host, port, template_dir, public_dir, templates

  def initialize(@env = Environment.new)
  end

  def start
    return unless @server.nil?

    @env.loader = @loader = Crinja::Loader::FileSystemLoader.new(template_dir)
    @env.context.merge! default_variables

    handlers = [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
      Crinja::Server::PlayHandler.new(@env, @logger),
      Crinja::Server::SourceHandler.new(@env, @logger),
      Crinja::Server::RenderHandler.new(@env, @logger),
      HTTP::StaticFileHandler.new(public_dir),
    ]

    @server = HTTP::Server.new(host, port, handlers)

    server.bind

    url = "http://#{host}:#{port}".colorize(:cyan)
    puts "Crinja server is listening on #{url}"

    server.listen
  end

  private def default_variables
    {
      "crinja" => {
        "version" => Crinja::VERSION,
        "server"  => self,
      },
    }
  end

  def templates
    loader.list_templates.map(&.as(Type))
  end
end

require "./server/template_handler"
require "./server/*"
