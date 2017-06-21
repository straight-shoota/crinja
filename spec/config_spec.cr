require "./spec_helper.cr"

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
end
