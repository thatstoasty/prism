"""The `FromFlagValue` trait, which turns a flag's raw text into a typed value."""
from std.builtin.rebind import rebind_var


trait FromFlagValue(Movable):
    """A type that can be constructed from the text a flag was given on the command line.

    Conforming types can be read straight out of a `FlagSet`:

    ```mojo
    var port = flags.get[Int]("port")
    ```

    The types a flag can hold already conform, via extensions, so this trait is mostly of interest
    when adding a type of your own.
    """

    def __init__(out self, value: StringSlice) raises:
        """Constructs the type from a flag's raw value.

        Args:
            value: The text the flag was given.

        Raises:
            Error: If the text does not represent a valid value of this type.
        """
        ...


__extension String(FromFlagValue):
    def __init__(out self, value: StringSlice) raises:
        """Constructs a `String` from a flag's raw value.

        Args:
            value: The text the flag was given.

        Raises:
            Error: Never; a flag value is already text.
        """
        # Not `Self(value)`: that resolves back to this initializer and recurses forever.
        self = String()
        self.write(value)


__extension Bool(FromFlagValue):
    def __init__(out self, value: StringSlice) raises:
        """Constructs a `Bool` from a flag's raw value.

        Args:
            value: The text the flag was given.

        Raises:
            Error: If the text is not a recognized boolean spelling.
        """
        # Same spellings as `strconv.ParseBool`, matching `_util.string_to_bool`.
        if value == "1" or value == "t" or value == "T" or value == "true" or value == "True" or value == "TRUE":
            self = True
        elif value == "0" or value == "f" or value == "F" or value == "false" or value == "False" or value == "FALSE":
            self = False
        else:
            raise Error(
                "Invalid boolean value: '",
                value,
                "'. Expected one of: 1, t, T, true, True, TRUE, 0, f, F, false, False, FALSE.",
            )


__extension SIMD(FromFlagValue):
    def __init__(out self, value: StringSlice) raises:
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
            self = Scalar[Self.dtype](atof(value))
        else:
            self = Scalar[Self.dtype](atol(value))


__extension List(FromFlagValue):
    def __init__(out self, value: StringSlice) raises:
        """Constructs a list from a flag's space separated raw value.

        Args:
            value: The text the flag was given, with elements separated by spaces.

        Raises:
            Error: If an element does not parse as the list's element type.
        """
        # Each arm builds a concrete list and rebinds it, rather than appending `Self.T` values
        # directly. Parsing an element can raise, and a partially filled `List[Self.T]` cannot be
        # unwound, because `List`'s own parameter bound does not promise the elements are
        # `Deinitable`. A concrete element type does.
        comptime if Self.T == String:
            var parsed = List[String]()
            for item in value.split(sep=" "):
                parsed.append(String(item))
            self = rebind_var[List[Self.T]](parsed^)
        elif Self.T == Int:
            var parsed = List[Int]()
            for item in value.split(sep=" "):
                parsed.append(atol(item))
            self = rebind_var[List[Self.T]](parsed^)
        elif Self.T == Float64:
            var parsed = List[Float64]()
            for item in value.split(sep=" "):
                parsed.append(atof(item))
            self = rebind_var[List[Self.T]](parsed^)
        else:
            comptime assert False, String(
                "List flags hold String, Int or Float64 elements. ",
                reflect[Self.T].name(),
                " is not one of them.",
            )
