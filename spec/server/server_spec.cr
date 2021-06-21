{% skip_file if flag?(:win32) %}
require "../spec_helper"
require "http/server"

describe Crinja::Server do
  typeof(begin
    env = Crinja.new
    handlers = [
      Crinja::Server::PlayHandler.new(env),
      Crinja::Server::SourceHandler.new(env),
      Crinja::Server::RenderHandler.new(env),
    ]

    server = HTTP::Server.new(handlers)
    server.listen
  end)
end
