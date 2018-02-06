require "../spec_helper.cr"

private module CacheTest
  class_property env
  @@env = Crinja.new
  class_property template_a
  @@template_a = Crinja::Template.new(source, env, name, file_name)
  class_property template_b
  @@template_b = Crinja::Template.new(source, env, "name_b", file_name)
end

private def env
  CacheTest.env
end

private def name
  "name"
end

private def file_name
  "file_name"
end

private def source
  "source"
end

describe Crinja::TemplateCache do
  describe Crinja::TemplateCache::NoCache do
    it "does not cache" do
      cache = Crinja::TemplateCache::NoCache.new
      cache.fetch(env, name, file_name, source) { CacheTest.template_a }
      cache.fetch(env, name, file_name, source) { CacheTest.template_b }.should eq CacheTest.template_b
    end
  end
  describe Crinja::TemplateCache::InMemory do
    it "does not cache" do
      cache = Crinja::TemplateCache::InMemory.new
      cache.fetch(env, name, file_name, source) { CacheTest.template_a }
      cache.fetch(env, name, file_name, source) { CacheTest.template_b }.should eq CacheTest.template_a
    end
  end
end
