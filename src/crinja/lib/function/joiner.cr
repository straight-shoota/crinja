Crinja.function({sep: ", "}, :joiner) do
  called = false
  sep = arguments[:sep].to_s
  ->(arguments : Arguments) {
    (if called
      sep
    else
      called = true
      nil
    end).as(Type)
  }.as(Type)
end
