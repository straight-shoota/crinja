require "./spec_helper"

describe "hello_world.html" do
  it "renders template" do
    render_file("hello_world.html", {
      "variable"  => "Value with <unsafe> data",
      "item_list" => [1, 2, 3, 4, 5, 6],
    }).should eq(rendered_file("hello_world.html"))
  end

  it "import" do
    render_file("import.html", {"name" => "World"}).should eq "Hello World!"
  end
end
