Crinja.function({sep: ", "}, :joiner) do
  called = false
  sep = arguments[:sep]
  ->(_args : Crinja::Callable::Arguments) do
    if called
      sep
    else
      called = true
      Crinja::Value.new ""
    end
  end
end
