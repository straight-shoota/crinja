require "json"

struct Crinja::JsonBuilder
  protected def initialize(value, indent = 0)
    @io = IO::Memory.new
    @json = JSON::Builder.new(@io)
    @json.indent = indent
    @json.start_document
    dump(value)
    @json.end_document
  end

  private def dump(value : Crinja::CallableMod)
    @json.null
  end

  private def dump(value : Crinja::TypeValue)
    unless value.is_a?(Callable)
      value.to_json(@json)
    else
      @json.string value.to_s
    end
  end

  private def dump(value)
    @json.string value.to_s
  end

  private def dump(hash : Hash)
    @json.object do
      hash.each do |key, value|
        @json.field key.to_s do
          dump(value)
        end
      end
    end
  end

  private def dump(array : Array)
    @json.array do
      array.each do |item|
        dump(item)
      end
    end
  end

  protected def to_string
    @io.to_s
  end

  def self.to_json(value, indent = 0)
    new(value, indent).to_string
  end
end
