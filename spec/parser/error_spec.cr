require "../spec_helper"

describe "errors" do
  it "unclosed tag" do
    error = expect_raises(Crinja::TemplateSyntaxError) do
      render("{% block")
    end
    error.token.position.should eq({0, 8})
  end
end
