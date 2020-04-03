require "option_parser"
require "log"
require "./crinja"

module Crinja::CLI
  Log = ::Log.for(self)

  @@env = Crinja.new
  @@loader = Crinja::Loader::FileSystemLoader.new("")
  @@env.loader = @@loader
  @@template_string : String?

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

  def self.print_library_defaults(only_names = false)
    [env.filters, env.tests, env.functions, env.tags, env.operators].each do |library|
      puts "#{library.name}s:"
      names = library.keys
      names += library.aliases.keys if only_names
      names.sort.each do |name|
        feature = library[name]
        if only_names
          puts "  #{name}"
        else
          puts "  #{feature}"
        end
      end
      puts
    end
  end

  def self.run
    OptionParser.parse! do |opts|
      library_defaults = false
      only_names = false

      opts.on("--version", "show version info") { puts Crinja::VERSION; exit }
      opts.on("--library-defaults", "print all default filters, tests, functions, tags and operators in stdlib") do
        library_defaults = true
      end
      opts.on("--only-names", "show only names of library defaults (combined with --library defaults)") do
        only_names = true
      end
      opts.missing_option do |option|
        case option
        when "--library-defaults"
          # it's okay to have no options
          print_library_defaults(false)
          exit
        else
          raise OptionParser::MissingOption.new(option)
        end
      end
      opts.on("-v", "--verbose", "") { Log.level = :debug }
      opts.on("-q", "--quiet", "") { Log.level = :warn }
      opts.on("-h", "--help", "") { self.display_help_and_exit(opts) }
      opts.on("-p PATH", "--path=PATH", "Add path for template lookup") { |path| loader.searchpaths << path }
      opts.on("--string=TEMPLATE", "template string") { |string| @@template_string = string }
      opts.on("-e VAR", "--extra-vars=VAR", "Set variables as `key=value` or YAML/JSON") do |var|
        key, value = var.split('=')
        env.context[key] = value
      end

      opts.unknown_args do |args, _|
        if !(string = @@template_string).nil?
          # read template from args
          template = env.from_string(string)
        elsif library_defaults
          print_library_defaults(only_names)
          exit
        elsif only_names
          puts "Can't use flag --only-names without --library-defaults"
          exit 1
        elsif args.empty?
          self.display_help_and_exit(opts)
          exit
        else
          template_file = args[0]

          template = env.get_template(template_file)
        end

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
  Crinja::CLI::Log.fatal ex.message
  exit 1
end
