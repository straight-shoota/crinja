require "json"

struct Crinja::JsonBuilder
  protected def initialize(@io : IO, indent = 0)
    @json = JSON::Builder.new(@io)
    @json.indent = indent
  end

  private def dump(value : Crinja::Callable)
    @json.null
  end

  private def dump(value : Crinja::TypeValue)
    unless value.is_a?(Callable | Callable::Proc)
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

  protected def to_json(value)
    @json.start_document
    dump(value)
    @json.end_document
  end

  def self.to_json(value, indent = 0)
    String.build do |io|
      to_json(value, io, indent)
    end
  end

  def self.to_json(io : IO, value, indent = 0)
    new(io, indent).to_json(value)
  end
end
