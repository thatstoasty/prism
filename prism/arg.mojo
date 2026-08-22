"""Positional arguments: their declaration, binding and typed retrieval."""
from std.collections.list import _ListIter

from prism.opt_type import OptType
from prism._util import _map_dtype_to_opt_type, _to_opt_string
from prism.value import ToValue


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
    def new[T: Movable & Deinitable](
        name: StringSpan,
        usage: StringSpan = "",
        var default: Optional[T] = None,
        required: Bool = True,
        valid_values: List[T] = [],
    ) -> Self:
        comptime assert conforms_to(T, ToValue), String(t"`T` must conform to `ToValue`. {reflect[T].name()} does not.")
        comptime opt_type = OptType(reflect[T].name())
        return Self(
            name=String(name),
            type=opt_type,
            usage=String(usage),
            required=required and not default,
            default=default^.and_then(_to_opt_string[T]),
            valid_values=[val.to_value() for val in valid_values],
        )
