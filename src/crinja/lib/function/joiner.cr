Crinja.function({sep: ", "}, :joiner) do
  called = false
  sep = arguments[:sep].to_s
  ->(_args : Crinja::Callable::Arguments) {
    (if called
      sep.as(Type)
    else
      called = true
      "".as(Type)
    end).as(Type)
  }.as(Type)
end
