"""`OptType`, the value type shared by flags and positional arguments."""


@fieldwise_init
struct OptType(Equatable, ImplicitlyCopyable):
    """The type of value a flag or positional argument holds."""

    var value: UInt8
    """The value of the type."""
    comptime String = Self(0)
    """A string value."""
    comptime Bool = Self(1)
    """A boolean value."""
    comptime Int = Self(2)
    """A signed integer value."""
    comptime Int8 = Self(3)
    """An 8-bit signed integer value."""
    comptime Int16 = Self(4)
    """A 16-bit signed integer value."""
    comptime Int32 = Self(5)
    """A 32-bit signed integer value."""
    comptime Int64 = Self(6)
    """A 64-bit signed integer value."""
    comptime UInt = Self(7)
    """An unsigned integer value."""
    comptime UInt8 = Self(8)
    """An 8-bit unsigned integer value."""
    comptime UInt16 = Self(9)
    """A 16-bit unsigned integer value."""
    comptime UInt32 = Self(10)
    """A 32-bit unsigned integer value."""
    comptime UInt64 = Self(11)
    """A 64-bit unsigned integer value."""
    comptime Float16 = Self(12)
    """A 16-bit floating point value."""
    comptime Float32 = Self(13)
    """A 32-bit floating point value."""
    comptime Float64 = Self(14)
    """A 64-bit floating point value."""
    comptime StringList = Self(15)
    """A space separated list of strings."""
    comptime IntList = Self(16)
    """A space separated list of integers."""
    comptime Float64List = Self(17)
    """A space separated list of 64-bit floating point values."""

    def is_int_type(self) -> Bool:
        """Returns if the type is an integer type.

        Returns:
            True if the type is an integer type, False otherwise.
        """
        return self in [
            Self.Int,
            Self.Int8,
            Self.Int16,
            Self.Int32,
            Self.Int64,
            Self.UInt,
            Self.UInt8,
            Self.UInt16,
            Self.UInt32,
            Self.UInt64,
        ]

    def is_float_type(self) -> Bool:
        """Returns if the type is an float type.

        Returns:
            True if the type is an float type, False otherwise.
        """
        return self in [Self.Float16, Self.Float32, Self.Float64]

    def is_list_type(self) -> Bool:
        """Returns if the type is a list type.

        Returns:
            True if the type is a list type, False otherwise.
        """
        return self in [Self.StringList, Self.IntList, Self.Float64List]

    def __eq__(self, other: Self) -> Bool:
        """Compares two OptType objects for equality.

        Args:
            other: The other OptType to compare against.

        Returns:
            True if the OptTypes are equal, False otherwise.
        """
        return self.value == other.value
