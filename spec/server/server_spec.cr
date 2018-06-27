require "../spec_helper"
require "http/server"

describe Crinja::Server do
  typeof(begin
    env = Crinja.new
    logger = Logger.new(STDOUT)

    handlers = [
      Crinja::Server::PlayHandler.new(env, logger),
      Crinja::Server::SourceHandler.new(env, logger),
      Crinja::Server::RenderHandler.new(env, logger),
    ]

    server = HTTP::Server.new(handlers)
    server.listen
  end)
end
