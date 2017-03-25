require "spec"
require "../src/crinja"

FIXTURES       = "spec/fixtures"
FIXTURE_LOADER = Crinja::Loader::FileSystemLoader.new(FIXTURES)

def render_file(file, bindings, trim_blocks = nil)
  env = Crinja::Environment.new
  env.loader = FIXTURE_LOADER
  env.config.trim_blocks = trim_blocks unless trim_blocks.nil?
  tmpl = env.load(file)
  tmpl.render(bindings)
end

def rendered_file(file)
  File.read(File.join(FIXTURES, file + ".rendered")).rchop("\n")
end
