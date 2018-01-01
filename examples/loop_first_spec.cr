require "benchmark"
require "../spec/spec_helper"

it "loop.first is not slowing down" do
    items = [true] * 10
    template1 = %(
      {% for item in items -%}
        {% if item.name=="bob" %}
          <p>First {{item.name}}</p>
        {% else %}
          <p>Other {{item.name}}</p>
        {% endif %}
      {%- endfor %}
    )
    template2 = %(
      {% for item in items -%}
        {% if loop.first %}
          <p>First {{item.name}}</p>
        {% else %}
          <p>Other {{item.name}}</p>
        {% endif %}
      {%- endfor %}
    )

    time1 = Benchmark.measure { render(template1,{"items"=>items}) }
    time2 = Benchmark.measure { render(template2,{"items"=>items}) }

    puts time1
    puts time2
    time1.real.should be_close(time2.real,0.1)
end
