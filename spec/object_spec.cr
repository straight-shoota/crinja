require "spec"
require "../src/crinja"

private class SimpleAttributes
  include Crinja::Object::Auto

  @[Crinja::Attribute]
  def foo
    "foo"
  end

  @[Crinja::Attribute(ignore: true)]
  def ignore
    "ignore"
  end

  @[Crinja::Attribute(name: other_name)]
  def this_name
    "this_name"
  end

  getter with_getter = "with_getter"

  @[Crinja::Attribute]
  def predicate?
    true
  end
end

private class InheritedAttributes < SimpleAttributes
  @[Crinja::Attribute]
  def child_only
    "child_only"
  end
end

private class ComplexAttributes
  include Crinja::Object::Auto

  # TODO: Spec for compile-time raising in macro:
  # @[Crinja::Attribute]
  # def required_argument(arg : String)
  #   arg
  # end

  @[Crinja::Attribute]
  def optional_argument(arg : String = "optional_argument")
    arg
  end

  # TODO: Spec for compile-time raising in macro:
  # @[Crinja::Attribute]
  # def expecting_block
  #   yield

  #   arg
  # end

  @[Crinja::Attribute]
  protected def protected_method
    "protected_method"
  end
end

@[Crinja::Attributes]
private class ExposeAllAttributes
  include Crinja::Object::Auto

  def foo
    "foo"
  end

  @[Crinja::Attribute(ignore: true)]
  def ignore
    "ignore"
  end

  @[Crinja::Attribute(name: other_name)]
  def this_name
    "this_name"
  end

  getter with_getter = "with_getter"
end

@[Crinja::Attributes(expose: [exposed, exposed_getter, ignored])]
private class ExposeSelectedAttributes
  include Crinja::Object::Auto

  def exposed
    "exposed"
  end

  getter exposed_getter = "exposed_getter"

  @[Crinja::Attribute(ignore: true)]
  def ignored
    "ignored"
  end

  @[Crinja::Attribute(name: other_name)]
  def ignore_name
    "ignore_name"
  end

  def not_exposed
    "not_exposed"
  end
end

@[Crinja::Attributes]
private class PredicateAttributesDouble
  include Crinja::Object::Auto

  def predicate?
    "predicate?"
  end

  def predicate
    "predicate"
  end
end

describe Crinja::Object do
  describe Crinja::Attribute do
    it "simple" do
      gutta = SimpleAttributes.new
      gutta.crinja_attribute(Crinja::Value.new("foo")).should eq Crinja::Value.new("foo")
      gutta.crinja_attribute(Crinja::Value.new("other_name")).should eq Crinja::Value.new("this_name")
      gutta.crinja_attribute(Crinja::Value.new("nonexist")).should eq Crinja::Value.new(Crinja::Undefined.new("nonexist"))
      gutta.crinja_attribute(Crinja::Value.new("ignore")).should eq Crinja::Value.new(Crinja::Undefined.new("ignore"))
    end

    pending "with getter" do
      gutta = SimpleAttributes.new
      gutta.crinja_attribute(Crinja::Value.new("with_getter")).should eq Crinja::Value.new("with_getter")
    end

    it "complex" do
      gutta = ComplexAttributes.new
      gutta.crinja_attribute(Crinja::Value.new("optional_argument")).should eq Crinja::Value.new("optional_argument")
      gutta.crinja_attribute(Crinja::Value.new("protected_method")).should eq Crinja::Value.new("protected_method")
    end

    it "inherited attributes" do
      gutta = InheritedAttributes.new
      gutta.crinja_attribute(Crinja::Value.new("child_only")).should eq Crinja::Value.new("child_only")
      gutta.crinja_attribute(Crinja::Value.new("foo")).should eq Crinja::Value.new("foo")
      gutta.crinja_attribute(Crinja::Value.new("other_name")).should eq Crinja::Value.new("this_name")
      gutta.crinja_attribute(Crinja::Value.new("nonexist")).should eq Crinja::Value.new(Crinja::Undefined.new("nonexist"))
      gutta.crinja_attribute(Crinja::Value.new("ignore")).should eq Crinja::Value.new(Crinja::Undefined.new("ignore"))
    end
  end

  describe Crinja::Attributes do
    it "exposes all" do
      gutta = ExposeAllAttributes.new
      gutta.crinja_attribute(Crinja::Value.new("foo")).should eq Crinja::Value.new("foo")
      gutta.crinja_attribute(Crinja::Value.new("other_name")).should eq Crinja::Value.new("this_name")
      gutta.crinja_attribute(Crinja::Value.new("with_getter")).should eq Crinja::Value.new("with_getter")
      gutta.crinja_attribute(Crinja::Value.new("nonexist")).should eq Crinja::Value.new(Crinja::Undefined.new("nonexist"))
      gutta.crinja_attribute(Crinja::Value.new("ignore")).should eq Crinja::Value.new(Crinja::Undefined.new("ignore"))
    end

    it "exposes selected" do
      gutta = ExposeSelectedAttributes.new
      gutta.crinja_attribute(Crinja::Value.new("exposed")).should eq Crinja::Value.new("exposed")
      gutta.crinja_attribute(Crinja::Value.new("exposed_getter")).should eq Crinja::Value.new("exposed_getter")
      gutta.crinja_attribute(Crinja::Value.new("ignored")).should eq Crinja::Value.new(Crinja::Undefined.new("ignored"))
      gutta.crinja_attribute(Crinja::Value.new("other_name")).should eq Crinja::Value.new("ignore_name")
      gutta.crinja_attribute(Crinja::Value.new("not_exposed")).should eq Crinja::Value.new(Crinja::Undefined.new("not_exposed"))
    end
  end

  it "exposes predicate methods" do
    gutta = SimpleAttributes.new
    gutta.crinja_attribute(Crinja::Value.new("is_predicate")).should eq Crinja::Value.new(true)

    gutta = PredicateAttributesDouble.new
    gutta.crinja_attribute(Crinja::Value.new("predicate")).should eq Crinja::Value.new("predicate")
  end
end
