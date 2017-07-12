#! /usr/bin/env python
# This scripts renders the compat-suite with Jinja2 to make the results comparable
# with Crinja.
import pytest
from jinja2 import Environment, FileSystemLoader

COMPAT_SUITE_PATH = './spec/integration/compat-suite'
COMPAT_SUITE_TEMPLATES_PATH = COMPAT_SUITE_PATH + '/templates'
COMPAT_SUITE_EXPECTED_PATH = COMPAT_SUITE_PATH + '/expected'

@pytest.fixture
def env():
    '''returns a new environment.
    '''
    return Environment(loader=FileSystemLoader(COMPAT_SUITE_TEMPLATES_PATH))

def render_file(file):
  env = Environment(loader=FileSystemLoader(COMPAT_SUITE_TEMPLATES_PATH))
  defaults = create_compat_suite_env()

  template = env.get_template(file)

  output = template.render(**defaults).encode('utf-8')

  with open(COMPAT_SUITE_EXPECTED_PATH + '/' + file, 'w') as f:
    f.write(output)

  print "wrote %s" % file

def assert_file(file):
  env = Environment(loader=FileSystemLoader(COMPAT_SUITE_TEMPLATES_PATH))
  defaults = create_compat_suite_env()

  template = env.get_template(file)

  output = template.render(**defaults).encode('utf-8')

  with open(COMPAT_SUITE_EXPECTED_PATH + '/' + file, 'r') as f:
    expected = f.write(output)

  assert output == expected

def create_compat_suite_env():
  def url_for(name):
    if name == "home":
      return "vincent.is"
    return nil

  return dict(
    url_for=url_for,
    product=Product(),
    username="bob",
    friend_reviewed=True,
    number_reviews=2,
    show_more=True,
    reviews=[Review(), Review()],
    comments=[('bob', "comment 1"), ('jane', "comment 2")],
    a_tuple=(1, 2, 3),
    an_array_of_tuple=[(1, 2, 3), (1, 2, 3)],
    empty=[],
  )

class Product(object):
  def __init__(self):
    self.name = "Moto G"
    self.manufacturer = "Motorala"
    self.summary = "A phone"
    self.price = 100

class Review(object):
  def __init__(self):
    self.title = "My review"
    self.paragraphs = ["A", "B", "C"]

def render_compar_suite():
  render_file("basic.html")
  render_file("basic_inheritance.html")
  render_file("comment_alignment.html")
  render_file("comment.html")
  render_file("conditions.html")
  render_file("empty_loop.html")
  render_file("filters.html")
  render_file("global_fn.html")
  render_file("include.html")
  render_file("indexing.html")
  render_file("loops.html")
  render_file("loops_set_dot_access.html")
  render_file("loop_with_filters.html")
  render_file("magical_variable.html")
  render_file("many_variable_blocks.html")
  render_file("raw.html")
  render_file("use_macros.html")
  render_file("variables.html")
  render_file("variable_tests.html")

@pytest.mark.compat
class TestCompatSuite(object):

  def test_basic(self, env):
    assert_file("basic.html")

  def test_basic_inheritance(self, env):
    assert_file("basic_inheritance.html")

  def test_comment_alignment(self, env):
    assert_file("comment_alignment.html")

  def test_comment(self, env):
    assert_file("comment.html")

  def test_conditions(self, env):
    assert_file("conditions.html")

  def test_empty_loop(self, env):
    assert_file("empty_loop.html")

  def test_filters(self, env):
    assert_file("filters.html")

  def test_global_fn(self, env):
    assert_file("global_fn.html")

  def test_include(self, env):
    assert_file("include.html")

  def test_indexing(self, env):
    assert_file("indexing.html")

  def test_loops(self, env):
    assert_file("loops.html")

  def test_loops_set_dot_access(self, env):
    assert_file("loops_set_dot_access.html")

  def test_loop_with_filters(self, env):
    assert_file("loop_with_filters.html")

  def test_magical_variable(self, env):
    assert_file("magical_variable.html")

  def test_many_variable_blocks(self, env):
    assert_file("many_variable_blocks.html")

  def test_raw(self, env):
    assert_file("raw.html")

  def test_use_macros(self, env):
    assert_file("use_macros.html")

  def test_variables(self, env):
    assert_file("variables.html")

  def test_variable_tests(self, env):
    assert_file("variable_tests.html")


  # binding an arbitrary type as global scope?
  # def test_value_render(self, env):
  #  assert_file("value_render.html", Product())

if __name__ == "__main__":
  render_compar_suite()
