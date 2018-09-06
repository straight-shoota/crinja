require "./spec_helper.cr"

private def restricted_env
  config = Crinja::Config.new
  config.disabled_functions = ["debug"]
  config.disabled_filters = ["pprint"]
  config.disabled_tags = ["set"]

  Crinja.new(config)
end

describe Crinja::Config do
  describe Crinja::Config::Autoescape do
    it "match_extension?" do
      Crinja::Config::Autoescape.match_extension?(["html"], "index.html").should be_true
      Crinja::Config::Autoescape.match_extension?(["xml"], "index.html").should be_false
      Crinja::Config::Autoescape.match_extension?(["html"], "index.html.j2").should be_true
      Crinja::Config::Autoescape.match_extension?(["xml"], "index.html").should be_false
      Crinja::Config::Autoescape.match_extension?(["html"], "index.j2").should be_false
      Crinja::Config::Autoescape.match_extension?(["html", "text"], "path/index.text").should be_true
    end
  end

  describe "disabled" do
    it "uses enabled function" do
      restricted_env.from_string(%({{ range(1) }})).render.should eq "[0]"
    end
    it "disables function" do
      expect_raises(Crinja::SecurityError, "access to function `debug()` is disabled.") do
        restricted_env.from_string(%({{ debug() }})).render
      end
    end
    it "disables filter" do
      expect_raises(Crinja::SecurityError, "access to filter `pprint(verbose=false)` is disabled.") do
        restricted_env.from_string(%({{ "foo" | pprint }})).render
      end
    end
    it "disables tag" do
      expect_raises(Crinja::SecurityError, "access to tag `set~endset` is disabled.") do
        restricted_env.from_string(%({% set foo = "foo" %})).render
      end
    end
  end
end
