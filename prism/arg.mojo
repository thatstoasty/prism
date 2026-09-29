"""Positional arguments: their declaration, binding and typed retrieval."""
from std.collections.list import _ListIter

from prism.opt_type import OptType
from prism._util import _to_opt_string
from prism.value import FromValue, ParseCheckFn, ToValue, _parse_check


comptime ArgParseFn = ParseCheckFn
"""Checks that an argument's text parses as its declared type."""


def _argument_order_problem(args: List[Arg]) -> Optional[String]:
    """Checks that arguments are declared in an order they can bind in.

    Args:
        args: The arguments in declaration order.

    Returns:
        A description of the first problem found, or `None` when the order is valid.

    #### Notes:
    - Arguments bind by position, so an optional argument ahead of a required one takes the value
      meant for the required one. The count check then passes and the required argument silently
      reads as `None`.
    - A list argument takes every remaining value, so one declared before another argument would
      leave nothing for the arguments after it.
    - This returns the problem rather than reporting it, so `Command` can panic with it, since it
      is a mistake in the program, while `ArgSet.bind` raises it, and so the rules can be tested.
    """
    var optional = Optional[String]()
    for i in range(len(args)):
        ref arg = args[i]
        if arg.type.is_list_type() and i < len(args) - 1:
            return String(
                t"The list argument `{arg.name}` is declared before `{args[i + 1].name}`. A list "
                t"argument takes every remaining value, so it must be declared last."
            )

        if not arg.required:
            if not optional:
                optional = arg.name
        elif optional:
            return String(
                t"The required argument `{arg.name}` is declared after the optional argument "
                t"`{optional.value()}`. Required arguments must come first."
            )

    return None


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
    var parse_check: ArgParseFn
    """Raises if a bound value does not parse as this argument's declared type."""

    def __init__(
        out self,
        name: String,
        type: OptType,
        *,
        usage: String = "",
        var default: Optional[String] = None,
        required: Bool = True,
        var valid_values: List[String] = [],
        parse_check: ArgParseFn = _parse_check[String](),
    ):
        """Constructs a positional argument.

        Args:
            name: The name of the argument.
            type: The type the argument's value is expected to parse as.
            usage: What the argument is for.
            default: The value to use when the argument is omitted.
            required: Whether the argument must be supplied.
            valid_values: The values this argument accepts. Empty accepts any value.
            parse_check: Raises if a bound value does not parse as `type`. Prefer `Arg.new`, which
                derives this from its `T`.
        """
        self.name = name
        self.usage = usage
        self.type = type
        self.value = None
        self.default = default^
        self.required = required
        self.valid_values = valid_values^
        self.parse_check = parse_check

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
        """Constructs a positional argument holding a `T`.

        Parameters:
            T: The type of value the argument holds. Must conform to `ToValue` and `FromValue`.

        Args:
            name: The name of the argument. Used to look the value up, and shown uppercased in
                usage text.
            usage: What the argument is for. Shown in help output.
            default: The value to use when the argument is omitted. Supplying one makes the
                argument optional even if `required` is True.
            required: Whether the argument must be supplied.
            valid_values: The values the argument accepts. Empty accepts any value.

        Returns:
            The argument.

        #### Notes:
        - Arguments are bound by position in the order they are declared, and their count, types
          and `valid_values` are checked before the command's `run` function is called.
        """
        comptime assert conforms_to(T, ToValue), String(t"`T` must conform to `ToValue`. {reflect[T].name()} does not.")
        comptime assert conforms_to(T, FromValue), String(
            t"`T` must conform to `FromValue`. {reflect[T].name()} does not."
        )
        comptime opt_type = OptType(reflect[T].name())
        return Self(
            name=String(name),
            type=opt_type,
            usage=String(usage),
            required=required and not default,
            default=default^.and_then(_to_opt_string[T]),
            valid_values=[val.to_value() for val in valid_values],
            parse_check=_parse_check[T](),
        )
