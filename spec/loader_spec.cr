require "./spec_helper"

describe Crinja::Loader do
  describe Crinja::Loader::FileSystemLoader do
    it "#get_source" do
      loader = Crinja::Loader::FileSystemLoader.new(File.join(__DIR__, "fixtures"))

      env = Crinja.new
      template, path = loader.get_source(env, "hello_world.html")

      template.should contain %(<title>\{\{ variable \}\}</title>)
      path.should eq File.join(__DIR__, "fixtures", "hello_world.html")

      expect_raises(Crinja::TemplateNotFoundError) do
        loader.get_source(env, "does_not_exist.htm")
      end
    end

    it "#list_templates" do
      loader = Crinja::Loader::FileSystemLoader.new(File.join(__DIR__, "fixtures"))

      loader.list_templates.should contain "hello_world.html"
    end
  end
end
