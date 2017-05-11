class Crinja::Test
  # Return whether the object is callable.
  create_test Callable, target.callable?

  # Returns `true` if the variable is defined.
  # See the `default()` filter for a simple way to set undefined variables.
  create_test Defined, !target.undefined?

  # Returns `true` if the variable is undefined.
  create_test Undefined, target.undefined?

  # Returns `true` if the variable is nil.
  create_test None, target.raw.nil?

  # Returns `true` if the variable is nil.
  create_test Nil, target.raw.nil?

  # Returns `true` if the object is a mapping (dict etc.).
  create_test Mapping, target.mapping?

  # Check if a variable is divisible by a number.
  create_test Divisibleby, {num: nil}, target.to_i % arguments[:num].to_i == 0

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
  create_test Equalto, {other: nil}, target == arguments[:other]

  # Checks if an object points to the same memory address than another object:
  create_test Sameas, {other: nil}, target.sameas? arguments[:other]

  # Returns `true` if the variable is lowercased.
  create_test Lower, target.to_s.chars.all?(&.lowercase?)

  # Returns `true` if the variable is upcased.
  create_test Upper, target.to_s.chars.all?(&.uppercase?)

  # Returns `true` if the variable is a string.
  create_test String, target.string?

  # Returns `true` if the variable is a string.
  create_test Escaped, target.raw.is_a?(SafeString)

  # Returns `true` if the variable is a number.
  create_test Number, target.number?

  # Returns `true` if the variable is a sequence. Sequences are variables that are iterable.
  create_test Sequence, target.sequence?

  # Returns `true` if the variable is iterable.
  create_test Iterable, target.iterable?

  # This tests an integer if it is even.
  create_test Even, target.to_i.even?
  # This test an integer if it is odd.
  create_test Odd, target.to_i.odd?

  # Checks if value is less than other.
  create_test Lessthan, {other: 0}, target.to_i < arguments[:other].to_i

  # Checks if value is greater than other.
  create_test Greaterthan, {other: 0}, target.to_i > arguments[:other].to_i

  # Check if value is in seq.
  class In < Test
    name "in"
    arguments({seq: [] of Type})

    def call(arguments : Arguments) : Type
      seq = arguments[:seq]
      target = arguments.target.not_nil!
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
    end
  end

  register_default In
end
