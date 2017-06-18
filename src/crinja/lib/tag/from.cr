# Crinja supports putting often used code into macros. These macros can go into different templates
# and get imported from there. It’s important to know that imports can be cached and imported templates
# don’t have access to the current template variables, just the globals by default.
#
# See [Jinja2 Template Documentation](http://jinja.pocoo.org/docs/2.9/templates/#import) for details.
class Crinja::Tag::From < Crinja::Tag
  name "from"

  private def interpret(io : IO, renderer : Renderer, tag_node : TagNode)
    env = renderer.env
    parser = Parser.new(tag_node.arguments)
    source_expression, with_context, imports = parser.parse_from_tag

    template_name = env.evaluate(source_expression).to_s

    child = if with_context
              Environment.new(env)
            else
              Environment.new(config: env.config, loader: env.loader)
            end

    template = child.get_template(template_name)

    template.render(child)

    env.errors += child.errors

    imports.each do |from_name, import_name|
      if template.macros.has_key?(from_name)
        env.context.macros[import_name] = template.macros[from_name]
      elsif child.context.has_key?(from_name)
        env.context[import_name] = child.context[from_name]
      else
        raise RuntimeError.new("Unknown import `#{from_name}` in #{template}").at(tag_node)
      end
    end
  end

  private class Parser < ArgumentsParser
    def parse_from_tag
      source_expression = parse_expression

      expect_identifier "import"

      imports = Hash(String, String).new

      while true
        from_name = expect_identifier

        import_name = from_name

        if_identifier "as" do
          next_token
          import_name = expect_identifier
        end

        imports[from_name] = import_name

        break unless current_token.kind == Kind::COMMA
        next_token
      end

      with_context = false
      if_identifier ["with", "without"] do
        with_context = current_token.value != "without"
        next_token
        expect_identifier "context"
      end

      close

      {source_expression, with_context, imports}
    end
  end
end
