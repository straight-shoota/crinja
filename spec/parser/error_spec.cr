require "../spec_helper"

describe "errors" do
  it "unclosed tag" do
    error = expect_raises(Crinja::TemplateSyntaxError) do
      render("{% block")
    end
    error.location_start.should eq Crinja::Parser::StreamPosition.new(1, 9, 8)
  end

  describe "unexpected EOF" do
    it do
      expect_raises(Crinja::TemplateSyntaxError, "Unterminated expression") do
        parse(%({{ foo))
      end
    end

    it do
      expect_raises(Crinja::TemplateSyntaxError, "Unterminated tag") do
        parse(%({% for i in))
      end
    end

    it do
      expect_raises(Crinja::TemplateSyntaxError, "Unterminated note") do
        parse(%({# comment))
      end
    end

    it do
      expect_raises(Crinja::TemplateSyntaxError, "Unclosed tag, missing: endif") do
        parse(%({% if true %}))
      end
    end
  end
end
