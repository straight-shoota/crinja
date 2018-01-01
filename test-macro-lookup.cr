module Include
  macro foo
    def foo 
    end
  end
end

class Parent
  include Include

  foo 
end

class Foo < Parent
  include Include

  foo
end
