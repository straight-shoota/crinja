require "../spec_helper"

describe "error locations" do
  it "basic error" do
    exc = expect_raises(Crinja::UndefinedError, "non_existing is undefined.") do
      render <<-'TPL_HTML'
          <html>
            <div>{{ non_existing.prop }}</div>
          </div>
          TPL_HTML
    end

    exc.template.should_not be_nil
    exc.template.not_nil!.filename.should be_nil
    exc.variable_name.should eq "non_existing"

    exc.location_start.should eq({2, 11})
    exc.location_end.should eq({2, 28})
    exc.message.should contain "template: <string>"
    exc.message.should contain <<-'ERR'

        2 |   <div>{{ non_existing.prop }}</div>
        X |           ^~~~~~~~~~~~~~~~~

       ERR
  end

  it "complex expression" do
    exc = expect_raises(Crinja::UndefinedError, "site.authors[johannes] is undefined.") do
      render <<-'TPL_HTML', {"post" => {"author" => "johannes"}, "site" => {"authors" => {} of String => String}}
          <header>
          <div class="meta">
            {% if post.author %} by <span class="post-author">{{ site.authors[post.author].name }}</span>{% endif %}
          TPL_HTML
    end

    exc.variable_name.should eq "site.authors[johannes]"

    exc.location_start.should eq({3, 56})
    exc.location_end.should eq({3, 86})
    exc.message.should contain <<-'ERR'

       3 |   {% if post.author %} by <span class="post-author">{{ site.authors[post.author].name }}</span>{% endif %}
       X |                                                        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      ERR
  end
end
