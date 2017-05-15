class Crinja::Statement
  class Dict < Statement
    class Entry < Statement
      include ParentStatement

      property key : Statement, value : Statement?

      def initialize(@key, @value = nil)
        super(@key.token)
      end

      def <<(statement : Statement)
        @value = statement
        statement.parent = self
      end

      def inspect(io : IO, indent = 0)
        super(io, indent)

        io << "\n" << "  " * indent << "- "
        key.inspect(io, indent + 1)
        io << "\n" << "  " * indent << "- "
        value.try(&.inspect(io, indent + 1))
      end

      def accepts_children?
        @value != nil
      end

      def evaluate(env : Environment) : Type
        {key.evaluate(env), value.not_nil!.evaluate(env)}.as(::Tuple(Type, Type))
      end
    end

    include ParentStatement

    property children : Array(Entry) = [] of Entry

    def <<(entry : Statement)
      raise "cannot add #{entry} to dict" unless entry.is_a? Entry

      children << entry
      entry.parent = self
    end

    def evaluate(env : Environment) : Type
      hash = Hash(Type, Type).new
      children.each do |entry|
        key, value = entry.evaluate(env)
        hash[key] = value
      end

      hash
    end

    def accepts_children?
      true
    end
  end
end
