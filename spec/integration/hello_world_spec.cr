require "./spec_helper"

describe "hello_world.html" do
  pending "renders template" do
    # This spc fails because it whitespace trim behaviour is not fully clear in respect to leading
    # newline characters.
    # @see StringTrimmer
    render_file("hello_world.html", {
      "variable"  => "Value with <unsafe> data",
      "item_list" => [1, 2, 3, 4, 5, 6],
    }).should eq(rendered_file("hello_world.html"))
  end

  it "import" do
    render_file("import.html", {"name" => "World"}).should eq "Hello World!"
  end
end
