require "../spec_helper"

describe "errors" do
  it "unclosed tag" do
    error = expect_raises(Crinja::TemplateSyntaxError | Crinja::ExceptionWrapper) do
      render("{% block")
    end
    # error.location_start.should eq({0, 8})
  end
end
