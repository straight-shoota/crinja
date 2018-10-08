require "spec"
require "../../src/crinja"

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

describe Crinja::Object do
  describe Crinja::Attribute do
    it "simple" do
      gutta = SimpleAttributes.new
      gutta.getattr(Crinja::Value.new("foo")).should eq Crinja::Value.new("foo")
      gutta.getattr(Crinja::Value.new("other_name")).should eq Crinja::Value.new("this_name")
      gutta.getattr(Crinja::Value.new("nonexist")).should eq Crinja::Value.new(Crinja::Undefined.new("nonexist"))
      gutta.getattr(Crinja::Value.new("ignore")).should eq Crinja::Value.new(Crinja::Undefined.new("ignore"))
    end

    pending "with getter" do
      gutta = SimpleAttributes.new
      gutta.getattr(Crinja::Value.new("with_getter")).should eq Crinja::Value.new("with_getter")
    end

    it "complex" do
      gutta = ComplexAttributes.new
      gutta.getattr(Crinja::Value.new("optional_argument")).should eq Crinja::Value.new("optional_argument")
      gutta.getattr(Crinja::Value.new("protected_method")).should eq Crinja::Value.new("protected_method")
    end

    it "inherited attributes" do
      gutta = InheritedAttributes.new
      gutta.getattr(Crinja::Value.new("child_only")).should eq Crinja::Value.new("child_only")
      gutta.getattr(Crinja::Value.new("foo")).should eq Crinja::Value.new("foo")
      gutta.getattr(Crinja::Value.new("other_name")).should eq Crinja::Value.new("this_name")
      gutta.getattr(Crinja::Value.new("nonexist")).should eq Crinja::Value.new(Crinja::Undefined.new("nonexist"))
      gutta.getattr(Crinja::Value.new("ignore")).should eq Crinja::Value.new(Crinja::Undefined.new("ignore"))
    end
  end

  describe Crinja::Attributes do
    it "exposes all" do
      gutta = ExposeAllAttributes.new
      gutta.getattr(Crinja::Value.new("foo")).should eq Crinja::Value.new("foo")
      gutta.getattr(Crinja::Value.new("other_name")).should eq Crinja::Value.new("this_name")
      gutta.getattr(Crinja::Value.new("with_getter")).should eq Crinja::Value.new("with_getter")
      gutta.getattr(Crinja::Value.new("nonexist")).should eq Crinja::Value.new(Crinja::Undefined.new("nonexist"))
      gutta.getattr(Crinja::Value.new("ignore")).should eq Crinja::Value.new(Crinja::Undefined.new("ignore"))
    end

    it "exposes selected" do
      gutta = ExposeSelectedAttributes.new
      gutta.getattr(Crinja::Value.new("exposed")).should eq Crinja::Value.new("exposed")
      gutta.getattr(Crinja::Value.new("exposed_getter")).should eq Crinja::Value.new("exposed_getter")
      gutta.getattr(Crinja::Value.new("ignored")).should eq Crinja::Value.new(Crinja::Undefined.new("ignored"))
      gutta.getattr(Crinja::Value.new("other_name")).should eq Crinja::Value.new("ignore_name")
      gutta.getattr(Crinja::Value.new("not_exposed")).should eq Crinja::Value.new(Crinja::Undefined.new("not_exposed"))
    end
  end
end
