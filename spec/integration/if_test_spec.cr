require "./spec_helper"

describe "if_test" do
  it "renders template" do
    render("Hello {{name}}!

{% if test -%}
    How are you?
{%- endif %}", {
      "name" => "John",
      "test" => true,
    }).should eq("Hello John!

    How are you?
")
  end
end
