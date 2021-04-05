require "option_parser"
require "yaml"
require "crinja"
require "crinja/server"

class Crinja::Server
  module CLI
    def self.display_help_and_exit(opts)
      puts "crinja-server [options]"
      puts
      puts "Options:"
      puts opts
      exit
    end

    def self.run
      server = Crinja::Server.new

      OptionParser.parse do |opts|
        path = Dir.current

        opts.on("--version", "") { puts Crinja::VERSION; exit }
        opts.on("-v", "--verbose", "") { server.env.logger.level = ::Log::Severity::Debug }
        opts.on("-q", "--quiet", "") { server.env.logger.level = ::Log::Severity::Warn }
        opts.on("-h", "--help", "") { self.display_help_and_exit(opts) }
        opts.on("-b HOST", "--bind=HOST", "Bind to host (default: #{Server::DEFAULT_HOST}") do |host|
          server.host = host
        end
        opts.on("-p PORT", "--port=PORT", "Bind to port (default #{Server::DEFAULT_PORT}") do |port|
          server.port = port.to_i
        end
        opts.on("-e VAR", "--extra-vars=VAR", "Set variables as `key=value`") do |var|
          key, value = var.split('=')
          server.env.context[key] = value
        end
      end

      server.start
    end
  end
end

begin
  Crinja::Server::CLI.run
rescue ex : OptionParser::InvalidOption
  STDERR.puts ex.message
  exit 1
end
