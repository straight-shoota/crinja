require "../spec_helper.cr"

private class User
  include Crinja::PyObject

  property name : String
  property dob : Time

  def initialize(@name, @dob)
  end

  def age
    (Time.utc(2017, 6, 8) - @dob)
  end

  def getattr(attr : Crinja::Value)
    case attr.to_string
    when "name"
      name
    when "age"
      age.days / 365
    else
      Crinja::Undefined.new(attr.to_s)
    end
  end

  def __call__(name : String)
    if name == "days_old"
      ->(arguments : Crinja::Callable::Arguments) do
        self.age.days
      end
    end
  end

  def __getitem__(attr : Crinja::Value)
    raw = attr.raw
    if raw.responds_to?(:to_i)
      @name[raw.to_i].to_s
    else
      Crinja::Undefined.new(attr.to_s)
    end
  end
end

describe Crinja::PyObject do
  it "resolves __getitem__" do
    user = User.new("Tom", Time.utc(1974, 3, 28))
    evaluate_expression_raw(%(user[0]), {user: user}).should eq "T"
  end

  it do
    user = User.new("Tom", Time.utc(1974, 3, 28))
    render(%({{ user[0] | lower }}/{{ user.name }}: {{ user.age }} ({{ user.days_old() }} days)), {user: user}).should eq "t/Tom: 43 (15778 days)"
  end
end
