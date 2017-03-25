require "spec"
require "../src/crinja"

FIXTURES       = "spec/fixtures"
FIXTURE_LOADER = Crinja::Loader::FileSystemLoader.new(FIXTURES)

def render_file(file, bindings)
  env = Crinja::Environment.new
  env.loader = FIXTURE_LOADER
  env.load(file).render(bindings)
end

def rendered_file(file)
  File.read(File.join(FIXTURES, file + ".rendered"))
end
