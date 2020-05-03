require "../spec_helper.cr"

describe Crinja::Tag::Do do
  it "normal" do
    tpl = <<-'TPL'
      {%- set ary = [] -%}
      {%- for item in ["foo", "bar"] -%}
        {%- do array_push(ary, item) -%}
      {%- endfor -%}
      {{ ary }}
      TPL

    array_push = Crinja.function({array: [] of Crinja::Value, item: nil}, :array_push) do
      array = arguments["array"]
      item = arguments["item"]
      value = array.as_a.push(item)
      Crinja::Value.new(value)
    end

    env = Crinja.new
    env.functions["array_push"] = array_push
    env.from_string(tpl).render(env).should eq("['foo', 'bar']")
    env.resolve("ary").should eq Crinja::Value.new(["foo", "bar"])
  end
end
