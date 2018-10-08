module Crinja::Filter
  Crinja.filter({default_value: "", boolean: false}, :default) do
    default_value = arguments[:default_value]

    value = target.raw
    if target.undefined? || value.nil? || (arguments[:boolean].truthy? && !target.truthy?)
      default_value.raw
    else
      value
    end
  end
  Crinja::Filter::Library.alias :d, :default

  Crinja.filter({name: UNDEFINED}, :attr) do
    Resolver.resolve_getattr(arguments[:name], target)
  end

  Crinja.filter({verbose: false}, :pprint) do
    verbose = arguments[:verbose].truthy?

    String.build do |io|
      target.pretty_print(Crinja::PrettyPrint.new(io, verbose: verbose))
    end
  end
end

# :nodoc:
class Crinja::PrettyPrint < ::PrettyPrint
  property verbose : Bool

  def initialize(output : IO, maxwidth = 79, newline = "\n", indent = 0, @verbose = false)
    super(output, maxwidth, newline, indent)
  end
end
