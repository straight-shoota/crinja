require "./spec_helper"

private def compare_code_visitor(path, template)
  tmpl = load(template, loader: Crinja::Loader::FileSystemLoader.new(path))
  tmpl.to_string.should eq File.read(File.join(path, template)).chomp('\n')
end

describe "stringify template" do
  it "stringifies" do
    compare_code_visitor("spec/fixtures", "hello_world.html")
  end
end
