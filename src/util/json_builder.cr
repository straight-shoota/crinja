require "json"

struct Crinja::JsonBuilder
  protected def self.new(io : IO, indent = 0)
    builder = JSON::Builder.new(io)
    builder.indent = indent
    new(builder)
  end

  protected def initialize(@json : JSON::Builder)
  end

  private def dump(value)
    case value
    when Value
      dump(value.raw)
    when Callable, Callable::Proc
      @json.string value.to_s
    when Iterator, Array
      @json.array do
        value.each do |item|
          dump(item)
        end
      end
    when Hash
      @json.object do
        value.each do |key, value|
          @json.field key.to_s do
            dump(value)
          end
        end
      end
    when PyObject
      # FIXME: We need to detect if the class has a #to_json(JSON::Builder) method
      # pending https://github.com/crystal-lang/crystal/issues/5695
      @json.null
    else
      value.to_json(@json)
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

  def self.to_json(builder : JSON::Builder, value)
    new(builder).to_json(value)
  end
end
