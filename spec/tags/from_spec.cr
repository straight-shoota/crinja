require "../spec_helper.cr"

private def test_loader_from
  Crinja::Loader::HashLoader.new({
    "foomacro.html" => <<-'TPL'
      {% macro foomacro() %}foo{%endmacro%}
      TPL,
    "foobarmacros.html" => <<-'TPL'
      {% macro foomacro() %}foo{%endmacro%}
      {% macro barmacro() %}bar{%endmacro%}
      TPL,
  })
end

describe Crinja::Tag::From do
  it "imports macro" do
    render("{% from 'foomacro.html' import foomacro %}{{ foomacro() }}", loader: test_loader_from).should eq "foo"
  end
  it "imports macro" do
    render("{% from 'foobarmacros.html' import foomacro %}{{ foomacro() }}", loader: test_loader_from).should eq "foo"
  end
  it "fails with non-existant macro" do
    expect_raises(Crinja::RuntimeError, "Unknown import `barmacro`") do
      render("{% from 'foomacro.html' import barmacro %}", loader: test_loader_from).should eq "foo"
    end
  end
  describe "other macros" do
    it "are undefined" do
      render("{% from 'foobarmacros.html' import foomacro %}{{ barmacro is callable }}", loader: test_loader_from).should eq "false"
    end
    it "cannot be called" do
      expect_raises(Crinja::TypeError) do
        render("{% from 'foobarmacros.html' import foomacro %}{{ barmacro() }}", loader: test_loader_from)
      end
    end
  end
  it "overwrites existing macros" do
    render("{% macro foomacro() %}local{% endmacro %}{% from 'foomacro.html' import foomacro %}{{ foomacro() }}", loader: test_loader_from).should eq "foo"
  end
  it "local macro overwrites from" do
    render("{% from 'foomacro.html' import foomacro %}{% macro foomacro() %}local{% endmacro %}{{ foomacro() }}", loader: test_loader_from).should eq "local"
  end
  it "imports macro with alias" do
    render("{% from 'foomacro.html' import foomacro as aliasmacro %}{{ aliasmacro() }}", loader: test_loader_from).should eq "foo"
  end
  it "imports multiple macros" do
    render("{% from 'foobarmacros.html' import foomacro, barmacro %}{{ foomacro() }}|{{ barmacro() }}", loader: test_loader_from).should eq "foo|bar"
  end
  it "imports multiple macros with alias" do
    render("{% from 'foobarmacros.html' import foomacro as foo, barmacro as bar %}{{ foo() }}|{{ bar() }}", loader: test_loader_from).should eq "foo|bar"
  end
  it "imports multiple macros with alias" do
    render("{% from 'foobarmacros.html' import foomacro as barmacro, barmacro as foomacro %}{{ foomacro() }}|{{ barmacro() }}", loader: test_loader_from).should eq "bar|foo"
  end
  it "imports macro from variable source file" do
    render("{% from source import foomacro %}{{ foomacro() }}", {source: "foomacro.html"}, loader: test_loader_from).should eq "foo"
  end
end
