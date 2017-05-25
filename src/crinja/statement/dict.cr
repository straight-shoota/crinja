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

      def accepts_children?
        @value != nil
      end
    end

    include ParentStatement

    property children : Array(Entry) = [] of Entry

    def <<(entry : Statement)
      raise "cannot add #{entry} to dict" unless entry.is_a? Entry

      children << entry
      entry.parent = self
    end

    def accepts_children?
      true
    end
  end
end
