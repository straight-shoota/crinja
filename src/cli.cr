require "option_parser"
require "logger"
require "./crinja"

module Crinja::CLI
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  @@env = Crinja::Environment.new
  @@loader = Crinja::Loader::FileSystemLoader.new("")
  @@env.loader = @@loader

  def self.env
    @@env
  end

  def self.loader
    @@loader
  end

  def self.display_help_and_exit(opts)
    puts "crinja [options] <template>"
    puts
    puts "Options:"
    puts opts
    exit
  end

  def self.run
    OptionParser.parse! do |opts|
      path = Dir.current

      opts.on("--version", "") { puts Crinja::VERSION; exit }
      opts.on("-v", "--verbose", "") { self.logger.level = Logger::Severity::DEBUG }
      opts.on("-q", "--quiet", "") { self.logger.level = Logger::Severity::WARN }
      opts.on("-h", "--help", "") { self.display_help_and_exit(opts) }
      opts.on("-p PATH", "--path PATH", "Add path for template lookup") { |path| loader.searchpaths << path }
      opts.on("-e VAR", "--extra-vars=VAR", "Set variables as `key=value` or YAML/JSON") do |var|
        key, value = var.split('=')
        env.context[key] = value
      end

      opts.unknown_args do |args, options|
        if args.empty?
          self.display_help_and_exit(opts)
          exit
        end

        template_file = args[0]

        template = env.get_template(template_file)
        output = template.render

        puts output

        exit
      end
    end
  end

end

begin
  Crinja::CLI.run

rescue ex : OptionParser::InvalidOption
  Crinja::CLI.logger.fatal ex.message
  exit 1
end
