class Crinja::Server::RenderHandler
  include TemplateHandler

  def call(context)
    path = context.request.path

    template = load_template(path)

    vars = default_variables

    context.response.content_type = "text/html"
    time_to_render = Benchmark.measure "render #{path}" do
      template.render(context.response, vars)
    end

    @env.logger.info { "Time to render #{path}: #{time_to_render.colorize(:yellow)}" }
  rescue exc : Crinja::TemplateNotFoundError
    @env.logger.debug(exception: exc) { "Render handler failed" }
    call_next(context)
  end

  def default_variables
    Variables.new
  end
end
