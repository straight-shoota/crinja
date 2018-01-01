require "../src/crinja"
require "benchmark"

items = (0..100).each

template_with_first = Crinja::Template.new(<<-TEMPLATE
  {% for i in list %}
    {% if loop.first %}
    first
    {% else %}
    {{ i }}
    {% endif %}
  {% endfor %}
  TEMPLATE
  )

template_without_first = Crinja::Template.new(<<-TEMPLATE
  {% for i in list %}
    {% if holla %}
    first
    {% else %}
    {{ i }}
    {% endif %}
  {% endfor %}
  TEMPLATE
  )

Benchmark.ips do |bm|
  bm.report "with loop.first" { template_with_first.render({"list" => items, "holla" => false}) }
  bm.report "without loop.first" { template_without_first.render({"list" => items, "holla" => false}) }
end
