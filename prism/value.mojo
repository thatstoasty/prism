"""The `FromValue` trait, which turns a flag's raw text into a typed value."""
from std.builtin.rebind import rebind_var


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
            return Scalar[Self.dtype](atol(value))


__extension List(FromValue):
    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
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
            return rebind_var[List[Self.T]](parsed^)
        elif Self.T == Int:
            var parsed = List[Int]()
            for item in value.split(sep=" "):
                parsed.append(atol(item))
            return rebind_var[List[Self.T]](parsed^)
        elif Self.T == Float64:
            var parsed = List[Float64]()
            for item in value.split(sep=" "):
                parsed.append(atof(item))
            return rebind_var[List[Self.T]](parsed^)
        else:
            comptime assert False, String(
                "List flags hold String, Int or Float64 elements. ",
                reflect[Self.T].name(),
                " is not one of them.",
            )


trait ToValue(Movable, Deinitable):
    def to_value(self) -> String:
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
        comptime assert Self.length == 1, String(
            "Values hold scalars, not vectors. ", reflect[Self].name(), " has more than one lane."
        )
        return String(self)


__extension List(ToValue):
    def to_value(self) -> String:
        """Constructs a list from a flag's space separated raw value.

        Returns:
            The List as a string.
        """
        comptime assert conforms_to(Self.T, Writable), "The elements of the List must conform to `Writable`."
        return String(self)
