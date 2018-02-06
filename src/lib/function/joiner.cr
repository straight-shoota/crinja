Crinja.function({sep: ", "}, :joiner) do
  called = false
  sep = arguments[:sep].to_s
  ->(_args : Crinja::Callable::Arguments) {
    (if called
      sep.as(Crinja::Type)
    else
      called = true
      "".as(Crinja::Type)
    end).as(Crinja::Type)
  }.as(Crinja::Type)
end
