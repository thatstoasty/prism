"""The `FromValue` trait, which turns a flag's raw text into a typed value."""
from std.builtin.rebind import downcast


comptime LIST_SEPARATOR = "\0"
"""Separates the elements of a list flag's raw value.

Why NUL: argv entries and environment variables are C strings, which end at the first NUL byte, so
no value from the command line can contain one. Every printable separator collides with some real
value: spaces split `-H "A: 1"`, commas split `Accept: text/html, application/json`, and a quoted
argument can hold a newline. With NUL, each occurrence of a repeated flag stays exactly one element
and no escaping is needed.

Caveats:
- A value read from `file_path`, or a string handed to `FlagSet.from_args` directly, could contain
  a NUL and would be split there.
- A raw list value is not printable as is. Help swaps the separator for spaces when showing a
  default, and anything else that displays one must do the same.
- A `ToValue` element type must not emit NUL.

Storing list values as `List[String]` on `Flag` would remove the in-band separator entirely, but
`Flag.value` and `FromValue.from_value` are string based, so that is a breaking API change.
"""


trait FromValue(Movable, Deinitable):
    """A type that can be constructed from the text a flag was given on the command line.

    Conforming types can be read straight out of a `FlagSet`:

    ```mojo
    var port = flags.get[Int]("port")
    ```

    The types a flag can hold already conform, via extensions, so this trait is mostly of interest
    when adding a type of your own.
    """

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Constructs the type from a flag's raw value.

        Args:
            value: The text the flag was given.

        Returns:
            The parsed value.

        Raises:
            Error: If the text does not represent a valid value of this type.
        """
        ...


__extension String(FromValue):
    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Constructs a `String` from a flag's raw value.

        Args:
            value: The text the flag was given.

        Raises:
            Error: Never; a flag value is already text.
        """
        return String(value)


__extension Bool(FromValue):
    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Constructs a `Bool` from a flag's raw value.

        Args:
            value: The text the flag was given.

        Raises:
            Error: If the text is not a recognized boolean spelling.
        """
        # Same spellings as `strconv.ParseBool`, matching `_util.string_to_bool`.
        if value == "1" or value == "t" or value == "T" or value == "true" or value == "True" or value == "TRUE":
            return True
        elif value == "0" or value == "f" or value == "F" or value == "false" or value == "False" or value == "FALSE":
            return False
        else:
            raise Error(
                "Invalid boolean value: '",
                value,
                "'. Expected one of: 1, t, T, true, True, TRUE, 0, f, F, false, False, FALSE.",
            )


__extension SIMD(FromValue):
    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Constructs a scalar from a flag's raw value.

        Args:
            value: The text the flag was given.

        Raises:
            Error: If the text does not parse as a number of this type.
        """
        # `Int` is `SIMD[DType.int, 1]` and `UInt` is `SIMD[DType.uint, 1]`, so this one extension
        # covers every integer and float width a flag can hold.
        comptime assert Self.length == 1, String(
            "Flags hold scalars, not vectors. ", reflect[Self].name(), " has more than one lane."
        )
        comptime if Self.dtype in (DType.float16, DType.float32, DType.float64):
            return Scalar[Self.dtype](atof(value))
        else:
            # `atol` parses at the native width, and narrowing to a smaller type wraps rather than
            # failing, so 999 read as an Int8 silently became -25. Check the range first.
            #
            # The comparison is done in a width that can hold the bound: `UInt64.MAX` does not fit
            # in a signed `Int`, so converting it to one wraps to -1 and rejects every value.
            var parsed = atol(value)
            var out_of_range: Bool
            comptime if Self.dtype.is_signed():
                out_of_range = (
                    Int64(parsed) < Int64(Scalar[Self.dtype].MIN)
                    or Int64(parsed) > Int64(Scalar[Self.dtype].MAX)
                )
            else:
                out_of_range = parsed < 0 or UInt64(parsed) > UInt64(Scalar[Self.dtype].MAX)

            if out_of_range:
                raise Error(
                    t"Value out of range for {reflect[Self].name()}: {parsed}. "
                    t"Expected {Scalar[Self.dtype].MIN} to {Scalar[Self.dtype].MAX}."
                )

            return Scalar[Self.dtype](parsed)


__extension List(FromValue):
    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Constructs a list from a flag's raw value.

        Args:
            value: The text the flag was given, with elements separated by `LIST_SEPARATOR`.

        Raises:
            Error: If an element does not parse as the list's element type.

        #### Notes:
        - An empty value is an empty list. `to_value` renders an empty list as `""`, and splitting
          that yields one empty element, so an empty default read back as `[""]`, or failed to
          parse for a `List[Int]`. The cost is that a lone `--tags ""` also reads as empty.
        """
        comptime assert conforms_to(Self.T, FromValue), String(t"The type of the list elements must conform to `FromValue`. {reflect[Self.T].name()} does not.")

        # We checked if it conforms to FromValue, so we can downcast here.
        var parsed = List[downcast[Self.T, FromValue]]()
        if not value:
            return parsed^
        for item in value.split(sep=LIST_SEPARATOR):
            parsed.append(Self.T.from_value(item))
        return parsed^


comptime _ArrayElement = Copyable & FromValue
"""What an `Array` element must be to be parsed from a flag value."""


__extension Array(FromValue):
    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Constructs a fixed-size array from a flag's raw value, one element per value.

        Args:
            value: The text the flag was given, with elements separated by `LIST_SEPARATOR`.

        Raises:
            Error: If the number of values is not the array's length, or one does not parse.
        """
        comptime assert conforms_to(Self.T, FromValue), String(
            t"The elements of the Array must conform to `FromValue`. {reflect[Self.T].name()} does not."
        )
        comptime assert conforms_to(Self.T, Copyable), String(
            t"The elements of the Array must be `Copyable`. {reflect[Self.T].name()} is not."
        )
        if not value:
            raise Error(t"Expected {Self.length} values, received 0.")
        var parts = value.split(sep=LIST_SEPARATOR)
        if len(parts) != Self.length:
            raise Error(t"Expected {Self.length} values, received {len(parts)}.")

        # `Array` accepts elements that cannot be destroyed implicitly, so the array is built over
        # the element type viewed as `_ArrayElement`, which proves it can be, then rebound to `Self`.
        # There is no constructor that leaves elements uninitialized, so it is filled from the first
        # element and the rest are overwritten.
        comptime E = downcast[Self.T, _ArrayElement]
        var result = Array[E, Self.length](fill=E.from_value(parts[0]))
        for i in range(1, Self.length):
            result[i] = E.from_value(parts[i])
        return rebind_var[Self](result^)


comptime ParseCheckFn = def (ImmStringSpan) raises thin -> None
"""Checks that a flag or argument's text parses as its declared type."""


def _parse_check[T: Movable & Deinitable]() -> ParseCheckFn:
    """Builds the parse check for a flag or argument declared as `T`.

    Parameters:
        T: The type the flag or argument holds.

    Returns:
        A function that raises if its input does not parse as a `T`.

    #### Notes:
    - Parsing only has the runtime `OptType`, which cannot name a user-defined type, so it could
      never dispatch to the right `from_value`. Capturing it here, where `T` is still known, is
      what lets every type be checked the same way instead of a switch that silently skipped
      lists and custom types.
    - `T` is bounded loosely and asserted instead, because a type conforming through an
      `__extension` does not satisfy a `FromValue` parameter bound.
    """
    comptime assert conforms_to(T, FromValue), String(
        t"`T` must conform to `FromValue`. {reflect[T].name()} does not."
    )

    def check(value: ImmStringSpan) raises -> None:
        _ = T.from_value(value)

    return check


trait ToValue(Movable, Deinitable):
    """A type that can be rendered as the text a flag or argument carries.

    `Flag.new` and `Arg.new` store a `default`, and `Arg.new` its `valid_values`, by calling this.
    Those are read back with `FromValue.from_value`, so the two must be inverses of each other:
    `T.from_value(x.to_value())` has to reproduce `x`, or a default will not survive being declared.

    The types a flag can hold already conform, via extensions, so this trait is mostly of interest
    when adding a type of your own.
    """

    def to_value(self) -> String:
        """Renders the value as the text `FromValue.from_value` accepts.

        Returns:
            The value as a string.
        """
        ...


__extension String(ToValue):
    def to_value(self) -> String:
        """Constructs a `String` from a flag's raw value.

        Returns:
            A copy of the string.
        """
        return self.copy()


__extension Bool(ToValue):
    def to_value(self) -> String:
        """Constructs a `Bool` from a flag's raw value.

        Returns:
            The Bool as a string.
        """
        return String(self)


__extension SIMD(ToValue):
    def to_value(self) -> String:
        """Constructs a scalar from a flag's raw value.

        Returns:
            The SIMD Scalar as a string.
        """
        # `Int` is `SIMD[DType.int, 1]` and `UInt` is `SIMD[DType.uint, 1]`, so this one extension
        # covers every integer and float width a flag can hold.
        comptime assert Self.length == 1, t"Values hold scalars, not vectors. {reflect[Self].name()} has more than one lane."
        return String(self)


__extension List(ToValue):
    def to_value(self) -> String:
        """Renders the list as a flag's raw value.

        Returns:
            The elements separated by `LIST_SEPARATOR`.

        #### Notes:
        - This has to be the inverse of `List.from_value`, which splits on `LIST_SEPARATOR`.
          `String(self)` renders a list as `[a, b]`, which does not split back into its elements,
          so a list flag's default would not survive the round trip.
        """
        comptime assert conforms_to(Self.T, ToValue), String(
            t"The elements of the List must conform to `ToValue`. {reflect[Self.T].name()} does not."
        )
        var builder = String()
        for i in range(len(self)):
            if i > 0:
                builder.write(LIST_SEPARATOR)
            builder.write(self[i].to_value())

        return builder^


__extension Array(ToValue):
    def to_value(self) -> String:
        """Renders the array as a flag's raw value.

        Returns:
            The elements separated by `LIST_SEPARATOR`.
        """
        comptime assert conforms_to(Self.T, ToValue), String(
            t"The elements of the Array must conform to `ToValue`. {reflect[Self.T].name()} does not."
        )
        var builder = String()
        for i in range(Self.length):
            if i > 0:
                builder.write(LIST_SEPARATOR)
            builder.write(self[i].to_value())
        return builder^
