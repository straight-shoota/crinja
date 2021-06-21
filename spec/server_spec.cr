{% skip_file if flag?(:win32) %}
require "./spec_helper"
require "../src/server"

describe Crinja::Server do
  it do
    env = Crinja.new
    server = Crinja::Server.new(env)
    server.template_dir = File.join(__DIR__, "fixtures")
    server.setup
  end
end
