module Crinja::Server::TemplateHandler
  include HTTP::Handler

  def initialize(@env : Crinja, @logger : Logger)
  end

  def load_template(path)
    if path[-1] == '/'
      path += "index.html"
    end

    template = uninitialized Crinja::Template
    time_to_parse = Benchmark.measure "parse #{path}" do
      template = @env.get_template(path)
    end
    @logger.info "Time to parse #{path}: #{time_to_parse.colorize(:yellow)}"

    template
  end
end
