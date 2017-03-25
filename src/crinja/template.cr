require "./parser"

class Crinja::Template
  property macros : Hash(String, Crinja::Tag::Macro::MacroInstance) = Hash(String, Crinja::Tag::Macro::MacroInstance).new
  getter string, name
  getter env : Environment

  def initialize(e : Environment, @string : String, @name : String = "")
    # duplicate environment for this template to avoid spilling to global scope, but keep current scope
    # even if render method has finished
    @env = e.dup
    @root = Node::Root.new(self)
    Parser::TemplateParser.new(self, root).build
  end

  def root
    @root.not_nil!
  end

  def render(bindings = nil)
    String.build do |io|
      render(io, bindings)
    end
  end

  def render(io : IO, bindings = nil)
    env.with_scope(bindings) do
      render(io, env)
    end
  end

  def render(io : IO, env : Environment)
    root.children.each do |node|
      node.render(io, env)
    end
  end
end
