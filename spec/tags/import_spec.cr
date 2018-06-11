require "../spec_helper.cr"

private def test_loader_import
  Crinja::Loader::HashLoader.new({
    "macros.html" => <<-'TPL',
      {% macro testmacro() %}foo{%endmacro%}
      TPL
  })
end

describe Crinja::Tag::Import do
  it "imports macro" do
    render("{% import 'macros.html' %}{{ testmacro() }}", loader: test_loader_import).should eq "foo"
  end
  it "fails for unknown macro" do
    expect_raises(Crinja::TemplateNotFoundError) do
      render("{% import 'invalid.html' %}{{ testmacro() }}", loader: test_loader_import)
    end
  end
  it "imports aliased macro" do
    render("{% import 'macros.html' as macros %}{{ macros.testmacro() }}", loader: test_loader_import).should eq "foo"
  end
  it "imports aliased macro only in namespace" do
    render("{% import 'macros.html' as macros %}{{ testmacro is not callable }}", loader: test_loader_import).should eq "true"
  end
end
