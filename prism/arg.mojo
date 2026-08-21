"""Positional arguments: their declaration, binding and typed retrieval."""
from std.collections.list import _ListIter

from prism.opt_type import OptType


@fieldwise_init
struct Arg(Copyable, Writable):
    """A positional argument a command accepts.

    Arguments are bound by position in the order they are declared, but are read back by name.
    """

    var name: String
    """The name of the argument. Used in usage text and to look the value up."""
    var usage: String
    """What the argument is for."""
    var type: OptType
    """The type the argument's value is expected to parse as."""
    var value: Optional[String]
    """The raw text bound to this argument, if one was supplied."""
    var default: Optional[String]
    """The value to fall back on when the argument is omitted."""
    var required: Bool
    """Whether the argument must be supplied."""
    var valid_values: List[String]
    """The values this argument accepts. Empty means any value is accepted."""

    def __init__(
        out self,
        name: String,
        type: OptType,
        *,
        usage: String = "",
        var default: Optional[String] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ):
        """Constructs a positional argument.

        Args:
            name: The name of the argument.
            type: The type the argument's value is expected to parse as.
            usage: What the argument is for.
            default: The value to use when the argument is omitted.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.
        """
        self.name = name
        self.usage = usage
        self.type = type
        self.value = None
        self.default = default^
        self.required = required
        self.valid_values = valid_values^

    def write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the argument to a writer.

        Args:
            writer: The writer to write to.
        """
        writer.write("Arg(name=", self.name)
        if self.value:
            writer.write(", value=", repr(self.value.value()))
        if self.default:
            writer.write(", default=", repr(self.default.value()))
        writer.write(", type=", self.type.value, ", required=", self.required, ")")

    def value_or_default(self) -> Optional[String]:
        """Returns the bound value, or the default when nothing was bound.

        Returns:
            The argument's raw text, or `None` when it has neither.
        """
        if self.value:
            return self.value.value()
        elif self.default:
            return self.default.value()

        return None

    @staticmethod
    def string(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[String] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `String` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.String,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def bool(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Bool] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Bool` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Bool,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def int(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Int] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Int` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Int,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def int8(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Int8] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Int8` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Int8,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def int16(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Int16] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Int16` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Int16,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def int32(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Int32] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Int32` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Int32,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def int64(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Int64] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Int64` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Int64,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def uint(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[UInt] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `UInt` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.UInt,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def uint8(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[UInt8] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `UInt8` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.UInt8,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def uint16(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[UInt16] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `UInt16` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.UInt16,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def uint32(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[UInt32] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `UInt32` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.UInt32,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def uint64(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[UInt64] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `UInt64` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.UInt64,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def float16(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Float16] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Float16` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Float16,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def float32(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Float32] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Float32` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Float32,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )

    @staticmethod
    def float64(
        name: StringSpan,
        usage: StringSpan = "",
        default: Optional[Float64] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
    ) -> Arg:
        """Constructs a `Float64` positional argument.

        Args:
            name: The name of the argument, used in usage text and to look it up.
            usage: What the argument is for.
            default: The value to use when the argument is omitted. Implies `required=False`.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.

        Returns:
            The argument.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Arg(
            name=String(name),
            type=OptType.Float64,
            usage=String(usage),
            default=default_value^,
            required=required and not default,
            valid_values=valid_values^,
        )
