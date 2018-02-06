require "spec"
require "../../src/crinja"

FIXTURES       = "spec/fixtures"
FIXTURE_LOADER = Crinja::Loader::FileSystemLoader.new(FIXTURES)

def render_file(file, bindings, autoescape = nil, trim_blocks = nil)
  env = Crinja.new
  env.loader = FIXTURE_LOADER
  env.config.autoescape.default = autoescape unless autoescape.nil?
  env.config.trim_blocks = trim_blocks unless trim_blocks.nil?
  tmpl = env.get_template(file)
  tmpl.render(bindings)
end

def rendered_file(file, path = FIXTURES)
  File.read(File.join(path, file + ".rendered")).rchop("\n")
end
