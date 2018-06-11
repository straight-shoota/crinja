require "../spec_helper.cr"

describe Crinja::Tag::Raw do
  it "ignores raw content" do
    render(<<-'TPL').should eq <<-'RENDERED'
        {% raw %}
            <ul>
            {% for item in seq %}
                <li>{{ item }}</li>
            {% endfor %}
            </ul>
        {% endraw %}
        TPL

            <ul>
            {% for item in seq %}
                <li>{{ item }}</li>
            {% endfor %}
            </ul>

        RENDERED
  end

  it "ignores empty raw" do
    render(%({% raw %}{% endraw %})).should eq ""
  end
end
