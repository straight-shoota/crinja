class Crinja::Server::SourceRenderer
  def initialize(@env : Crinja::Environment)
  end

  def render(io, template)
    io << %(<link href="/source.css" rel="stylesheet">)
    io << %(<div class="crinja-server-notice">Crinja template code for <code>\
            <a href="#{template.name}">#{template.name}</a></code>:</div>)
    io << "<pre>"
    Crinja::Visitor::HTML.new(io).visit(template)
    io << "</pre>"
  end
end
