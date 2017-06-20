require "../spec_helper.cr"

private class User
  include Crinja::PyObject

  property name : String
  property dob : Time

  def initialize(@name, @dob)
  end

  def age
    (Time.new(2017, 6, 8) - @dob)
  end

  def getattr(attr)
    case attr
    when "name"
      name
    when "age"
      age.days / 365
    else
      Undefined.new(attr.to_s)
    end
  end

  def __call__(name)
    if name == "days_old"
      ->(arguments : Crinja::Callable::Arguments) do
        self.age.days.as(Crinja::Type)
      end
    end
  end

  def __getitem__(attr)
    if attr.responds_to?(:to_i)
      @name[attr.to_i].to_s
    else
      Undefined.new(attr.to_s)
    end
  end
end

describe Crinja::PyObject do
  it do
    user = User.new("Tom", Time.new(1974, 3, 28))
    render(%({{ user[0] | lower }}/{{ user.name }}: {{ user.age }} ({{ user.days_old() }} days)), {user: user}).should eq "t/Tom: 43 (15778 days)"
  end
end
