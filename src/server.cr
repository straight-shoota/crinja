require "http/server"
require "colorize"
require "benchmark"
require "log"

@[Crinja::Attributes(expose: [host, port, template_dir, public_dir, templates])]
class Crinja::Server
  Log = ::Log.for(self)

  DEFAULT_HOST = "0.0.0.0"
  DEFAULT_PORT = 7645

  property host : String = DEFAULT_HOST
  property port : Int32 = DEFAULT_PORT
  property template_dir : String = "pages"
  property public_dir : String = "public"

  getter env : Crinja
  getter! server : HTTP::Server
  getter! loader : Crinja::Loader

  include Crinja::Object::Auto

  def initialize(@env = Crinja.new)
  end

  def setup
    return unless @server.nil?

    raise "template_dir #{template_dir} does not exist" unless File.directory?(template_dir)
    raise "template_dir #{template_dir} is not readable" unless File.readable?(template_dir)

    @env.loader = @loader = Crinja::Loader::FileSystemLoader.new(template_dir)
    @env.context.merge! default_variables

    handlers = [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
      Crinja::Server::PlayHandler.new(@env),
      Crinja::Server::SourceHandler.new(@env),
      Crinja::Server::RenderHandler.new(@env),
      HTTP::StaticFileHandler.new(public_dir),
    ]

    @server = HTTP::Server.new(handlers)
  end

  def start
    setup

    address = server.bind_tcp(host, port)

    url = "http://#{address}".colorize(:cyan)
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
    loader.list_templates
  end
end

require "./server/template_handler"
require "./server/*"
