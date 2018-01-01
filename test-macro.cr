module Include
  def self.include_method
  end
  macro include_macro
    p "include_macro"
  end
end
class Parent
  include Include
  def self.parent_method
    :ok
  end
  macro parent_macro
    :macro
  end
end

class Foo < Parent
  
  parent_method                   # => ok
  parent_macro                    # => ok
  #include_method                  # => undefined local variable or method 'include_method'
  include_macro                   # => undefined local variable or method 'include_macro'
end
