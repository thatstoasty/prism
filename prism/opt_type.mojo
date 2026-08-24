"""`OptType`, the value type shared by flags and positional arguments."""
@fieldwise_init
struct OptType(Equatable, ImplicitlyCopyable, Writable):
    """The type of value a flag or positional argument holds."""

    var value: UInt8
    """The value of the type."""
    var name: StaticString
    """The reflected name of the Mojo type this was derived from.

    Two different user-defined types both land on `Custom`, so the discriminant alone cannot tell
    them apart. Carrying the name here does, and since equality is field-wise, a lookup for one
    custom type no longer matches a flag declared as another. `reflect` reports a qualified name,
    so identically named types in different modules stay distinct too.
    """
    comptime String = Self(0, "String")
    """A string value."""
    comptime Bool = Self(1, "Bool")
    """A boolean value."""
    comptime Int = Self(2, "Int")
    """A signed integer value."""
    comptime Int8 = Self(3, "Int8")
    """An 8-bit signed integer value."""
    comptime Int16 = Self(4, "Int16")
    """A 16-bit signed integer value."""
    comptime Int32 = Self(5, "Int32")
    """A 32-bit signed integer value."""
    comptime Int64 = Self(6, "Int64")
    """A 64-bit signed integer value."""
    comptime UInt = Self(7, "UInt")
    """An unsigned integer value."""
    comptime UInt8 = Self(8, "UInt8")
    """An 8-bit unsigned integer value."""
    comptime UInt16 = Self(9, "UInt16")
    """A 16-bit unsigned integer value."""
    comptime UInt32 = Self(10, "UInt32")
    """A 32-bit unsigned integer value."""
    comptime UInt64 = Self(11, "UInt64")
    """A 64-bit unsigned integer value."""
    comptime Float16 = Self(12, "Float16")
    """A 16-bit floating point value."""
    comptime Float32 = Self(13, "Float32")
    """A 32-bit floating point value."""
    comptime Float64 = Self(14, "Float64")
    """A 64-bit floating point value."""
    comptime List = Self(15, "List")
    """A space separated list of values that can be converted to/from strings."""
    comptime Custom = Self(16, "Custom")
    """Custom types."""

    def __init__(out self, type: StaticString):
        """Constructs the `OptType` matching a Mojo type's name.

        Args:
            type: A type name as reported by `reflect[T].name()`.

        #### Notes:
        - `Flag.new` and `Arg.new` use this to derive a flag or argument's type from their `T`,
          which is what tells the parser whether it takes a following value.
        - The scalar names are the reflected spellings, so `Int` arrives as `SIMD[DType.int, 1]`
          rather than `Int`. Anything unrecognized becomes `Custom`, which is how a user's own type
          is accommodated; note that every such type shares that one value.
        """
        if type == "String":
            return Self.String
        elif type == "Bool":
            return Self.Bool
        elif type == "SIMD[DType.int, 1]":
            return Self.Int
        elif type == "SIMD[DType.int8, 1]":
            return Self.Int8
        elif type == "SIMD[DType.int16, 1]":
            return Self.Int16
        elif type == "SIMD[DType.int32, 1]":
            return Self.Int32
        elif type == "SIMD[DType.int64, 1]":
            return Self.Int64
        elif type == "SIMD[DType.uint, 1]":
            return Self.UInt
        elif type == "SIMD[DType.uint8, 1]":
            return Self.UInt8
        elif type == "SIMD[DType.uint16, 1]":
            return Self.UInt16
        elif type == "SIMD[DType.uint32, 1]":
            return Self.UInt32
        elif type == "SIMD[DType.uint64, 1]":
            return Self.UInt64
        elif type == "SIMD[DType.float16, 1]":
            return Self.Float16
        elif type == "SIMD[DType.float32, 1]":
            return Self.Float32
        elif type == "SIMD[DType.float64, 1]":
            return Self.Float64
        elif type.startswith("List"):
            # Keep the name: `List[String]` and `List[Int]` are different types, and without it a
            # lookup for one matches a flag declared as the other.
            return Self(Self.List.value, type)
        else:
            # Keep the name: it is the only thing distinguishing one custom type from another.
            return Self(Self.Custom.value, type)

    def is_custom_type(self) -> Bool:
        """Returns if the type came from a user-defined type.

        Returns:
            True if the type is a custom type, False otherwise.

        #### Notes:
        - Comparing against `OptType.Custom` directly does not work, because every custom type
          carries its own name to keep it distinct from other custom types, and equality is
          field-wise. This compares only the discriminant.
        """
        return self.value == Self.Custom.value

    def is_list_type(self) -> Bool:
        """Returns if the type is a list of values.

        Returns:
            True if the type is a list type, False otherwise.

        #### Notes:
        - Comparing against `OptType.List` directly does not work, because a list carries its
          element type in its name to stay distinct from lists of other elements, and equality is
          field-wise. This compares only the discriminant.
        """
        return self.value == Self.List.value

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
