# templates and specs are derived from https://github.com/Keats/tera/blob/master/tests/render_ok.rs
require "./spec_helper.cr"
require "diff"
require "colorize"

COMPAT_SUITE_PATH = "./compat-suite"
COMPAT_SUITE_TEMPLATES_PATH = "#{COMPAT_SUITE_PATH}/templates"
COMPAT_SUITE_EXPECTED_PATH = "#{COMPAT_SUITE_PATH}/expected"
COMPAT_SUITE_LOADER = Crinja::Loader::FileSystemLoader.new(File.join(__DIR__, COMPAT_SUITE_TEMPLATES_PATH))

private def create_compat_suite_env
  env = Crinja::Environment.new(loader: COMPAT_SUITE_LOADER)
  env.functions["url_for"] = Crinja.function({name: Crinja::UNDEFINED}) do
    case arguments[:name].as_s!
    when "home"
      "vincent.is"
    else
      nil
    end
  end
  env.context.merge!({
    product: Product.new,
    username: "bob",
    friend_reviewed: true,
    number_reviews: 2,
    show_more: true,
    reviews: [Review.new, Review.new],
    comments: {
      bob: "comment 1",
      jane: "comment 2",
      },
    a_tuple: {1, 2, 3},
    an_array_of_tuple: [{1, 2, 3}, {1, 2, 3}],
    empty: [] of Review,
    })
  env
end

struct EqualStringExpectation(T)
  def initialize(@expected_value : T)
  end

  def match(actual_value)
    actual_value == @expected_value
  end

  def failure_message(actual_value)
    expected = @expected_value.inspect
    got = actual_value.inspect
    if expected == got
      "Expected class: #{@expected_value.class}\nGot class: #{actual_value.class}"
    else
      str = String.build do |io|
        Diff.diff(@expected_value, actual_value).each do |chunk|
          s = chunk.data
          if s == "\n"
            s = "¶\n"
          end
          if chunk.append?
            s = s.colorize(:green).back(:light_green)
          elsif chunk.delete?
            s = s.colorize(:red).back(:light_red)
          else
            s = s.colorize(:dark_gray)
          end
          io << s
        end
      end
      if false
        print_char_reading @expected_value, actual_value
        pp @expected_value <=> actual_value
        pp @expected_value.chars, @expected_value.to_slice
        pp actual_value.chars, actual_value.to_slice
        puts "---"
        puts str
        puts "---"
      end
      str
    end
  end

  def print_char_reading(a, b)
    a = a.each_char
    b = b.each_char
    while (x = a.next) && (y = b.next)
      break if x.is_a?(Iterator::Stop) || y.is_a?(Iterator::Stop)
      s = sprintf "%s %03d | %03d %s", x.dump, x.ord, y.ord, y.dump
      if x == y
        s = s.colorize(:dark_gray)
      else
        s = s.colorize(:red)
      end
      puts s
    end
  end

  def negative_failure_message(actual_value)
    "Expected: actual_value != #{@expected_value.inspect}\n     got: #{actual_value.inspect}"
  end
end


private record Product, name = "Moto G", manufacturer = "Motorala", summary = "A phone", price = 100 do
  include Crinja::PyObject
  getattr
end

private record Review, title = "My review", paragraphs = ["A", "B", "C"] do
  include Crinja::PyObject
  getattr
end

private def assert_render(file, bindings = nil)
  env = create_compat_suite_env
  expectation = EqualStringExpectation.new(File.read(File.join(__DIR__, COMPAT_SUITE_EXPECTED_PATH, file)))
  env.get_template(file).render(bindings).should expectation
end

describe "compat-suite" do
  it("basic.html") { assert_render("basic.html") }
  it("basic_inheritance.html") { assert_render("basic_inheritance.html") }
  it("comment_alignment.html") { assert_render("comment_alignment.html") }
  it("comment.html") { assert_render("comment.html") }
  it("conditions.html") { assert_render("conditions.html") }
  it("empty_loop.html") { assert_render("empty_loop.html") }
  it("filters.html") do
    file = "filters.html"
    env = create_compat_suite_env
    rendered = File.read(File.join(__DIR__, COMPAT_SUITE_EXPECTED_PATH, file))
    # `{{ "Motorola" | truncate(length=5) }}` evaluates to `M ...` in Jinja2 and `M...` in Crinja
    rendered = rendered.gsub("M ...", "M...")
    expectation = EqualStringExpectation.new(rendered)
    env.get_template(file).render.should expectation
  end
  it("global_fn.html") { assert_render("global_fn.html") }
  it("include.html") { assert_render("include.html") }
  it("indexing.html") { assert_render("indexing.html") }
  it("loops.html") { assert_render("loops.html") }
  it("loops_set_dot_access.html") { assert_render("loops_set_dot_access.html") }
  it("loop_with_filters.html") { assert_render("loop_with_filters.html") }
  it("magical_variable.html") { assert_render("magical_variable.html") }
  it("many_variable_blocks.html") { assert_render("many_variable_blocks.html") }
  it("raw.html") { assert_render("raw.html") }
  it("use_macros.html") { assert_render("use_macros.html") }
  it("variables.html") { assert_render("variables.html") }
  it("variable_tests.html") { assert_render("variable_tests.html") }

  # binding an arbitrary type as global scope is neither supported in Jinja2 nor Crinja
  # pending "value_render.html" do
  #   assert_render("value_render.html", Product.new)
  # end
end
