class Crinja::Test
  # Return whether the object is callable.
  create_test(Callable, default: true) { target.callable? }

  # Returns `true` if the variable is defined.
  # See the `default()` filter for a simple way to set undefined variables.
  create_test(Defined, default: true) { !target.undefined? }

  # Returns `true` if the variable is undefined.
  create_test(Undefined, default: true) { target.undefined? }

  # Returns `true` if the variable is nil.
  create_test(None, default: true) { target.raw.nil? }

  # Returns `true` if the variable is nil.
  create_test(Nil, default: true) { target.raw.nil? }

  # Returns `true` if the object is a mapping (dict etc.).
  create_test(Mapping, default: true) { target.mapping? }

  # Check if a variable is divisible by a number.
  create_test(Divisibleby, {num: nil}, default: true) { target.to_i % arguments[:num].to_i == 0 }

  # Check if an object has the same value as another object:
  # ```
  # {% if foo.expression is equalto 42 %}
  #     the foo attribute evaluates to the constant 42
  # {% endif %}
  # ```
  # This appears to be a useless test as it does exactly the same as the == operator, but it can be useful when used together with the selectattr function:
  # ```
  # {{ users | selectattr("email", "equalto", "foo@bar.invalid") }}
  # ```
  create_test(Equalto, {other: nil}, default: true) { target == arguments[:other] }

  # Checks if an object points to the same memory address than another object:
  create_test(Sameas, {other: nil}, default: true) { target.sameas? arguments[:other] }

  # Returns `true` if the variable is lowercased.
  create_test(Lower, default: true) { target.to_s.chars.all?(&.lowercase?) }

  # Returns `true` if the variable is upcased.
  create_test(Upper, default: true) { target.to_s.chars.all?(&.uppercase?) }

  # Returns `true` if the variable is a string.
  create_test(String, default: true) { target.string? }

  # Returns `true` if the variable is a string.
  create_test(Escaped, default: true) { target.raw.is_a?(SafeString) }

  # Returns `true` if the variable is a number.
  create_test(Number, default: true) { target.number? }

  # Returns `true` if the variable is a sequence. Sequences are variables that are iterable.
  create_test(Sequence, default: true) { target.sequence? }

  # Returns `true` if the variable is iterable.
  create_test(Iterable, default: true) { target.iterable? }

  # This tests an integer if it is even.
  create_test(Even, default: true) { target.to_i.even? }
  # This test an integer if it is odd.
  create_test(Odd, default: true) { target.to_i.odd? }

  # Checks if value is less than other.
  create_test(Lessthan, {other: 0}, default: true) { target.to_i < arguments[:other].to_i }

  # Checks if value is greater than other.
  create_test(Greaterthan, {other: 0}, default: true) { target.to_i > arguments[:other].to_i }

  # Check if value is in seq.
  create_test(In, {seq: Array(Type).new}, default: true) {
    seq = arguments[:seq]
    raw = seq.raw
    case raw
    when Hash
      raw.has_key? target.raw
    when Enumerable
      raw.includes? target.raw
    else
      if seq.string?
        seq.to_s.includes?(target.to_s)
      else
        raise seq.inspect
      end
    end
  }
end
