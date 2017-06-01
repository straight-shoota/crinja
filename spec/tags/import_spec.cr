require "../spec_helper.cr"

private def test_loader_import
  Crinja::Loader::HashLoader.new({
    "macros.html" => <<-'TPL'
      {% macro testmacro() %}foo{%endmacro%}
      TPL,
    })
end

describe Crinja::Tag::Import do
  it "imports macro" do
    render("{% import 'macros.html' %}{{ testmacro() }}", loader: test_loader_import).should eq "foo"
  end
end
