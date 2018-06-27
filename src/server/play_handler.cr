require "yaml"

class Crinja::Server::PlayHandler
  include HTTP::Handler

  DEFAULT_TEMPLATE = <<-'END'
    <ul>
      {%- for user in users | sort(attribute="name") -%}
      <li><a href="/users/{{ user.id }}">{{ user.name }}</a></li>
      {%- endfor -%}
    </ul>
    END

  DEFAULT_VARIABLES = <<-'END'
      users:
      - id: 1
        name: "john"
      - id: 2
        name: "james"
      - id: 3
        name: "mike"
      - id: 4
        name: "mat"
      END

  def initialize(@env : Crinja, @logger : Logger)
  end

  def call(context)
    return call_next(context) unless context.request.path == "/play"

    template_source = nil
    variables = nil

    if context.request.method == "POST"
      if body = context.request.body
        params = HTTP::Params.parse(body.gets_to_end)

        template_source = params["template_source"]?
        variables = params["variables"]?
      else
        context.response.status_code = 400
      end

      unless template_source && variables
        context.response.status_code = 400
        return
      end
    end

    template_source ||= DEFAULT_TEMPLATE
    variables ||= DEFAULT_VARIABLES
    bindings = YAML.parse(variables)

    rendered_result = ""
    begin
      template = @env.from_string template_source

      begin
        rendered_result = template.render(bindings.as_h)
      rescue e : Crinja::Error
        e.template = template
        rendered_result = e.to_s
        @logger.error e.to_s
      end
    rescue e : Crinja::TemplateError
      rendered_result = e.to_s
      @logger.error e.to_s
    end

    context.response.content_type = "text/html"
    @env.get_template("play.html").render(context.response, {
      template_source: template_source,
      variables:       variables,
      rendered_result: SafeString.new(rendered_result),
    })
  end
end
