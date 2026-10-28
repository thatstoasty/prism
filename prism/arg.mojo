"""Positional arguments: their declaration, binding and typed retrieval."""
from std.collections.list import _ListIter

from prism.opt_type import OptType
from prism._util import _to_opt_string
from prism.value import FromValue, LIST_SEPARATOR, ParseCheckFn, ToValue, _parse_check


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
    def new[T: Movable & Deinitable, E: Movable & Deinitable = T](
        name: StringSpan,
        usage: StringSpan = "",
        var default: Optional[T] = None,
        required: Bool = True,
        valid_values: List[E] = [],
    ) -> Self:
        """Constructs a positional argument holding a `T`.

        ```mojo
        Arg.new[String](name="env", usage="Environment.", valid_values=["staging", "production"])
        Arg.new[List[String]](name="shells", usage="Shells to set up.", valid_values=["zsh", "bash"])
        ```

        Parameters:
            T: The type of value the argument holds. Must conform to `ToValue` and `FromValue`.
            E: The type of `valid_values`, inferred from them, so it is never written. It is `T`, or
                for a list argument, the list's element type, so that `valid_values` constrains
                each element. Defaults to `T` when no `valid_values` are given.

        Args:
            name: The name of the argument. Used to look the value up, and shown uppercased in
                usage text.
            usage: What the argument is for. Shown in help output.
            default: The value to use when the argument is omitted. Supplying one makes the
                argument optional even if `required` is True.
            required: Whether the argument must be supplied. For a list argument, whether at least
                one value must be supplied.
            valid_values: The values the argument accepts, or for a list argument, the values each
                element may take. Empty accepts any value.

        Returns:
            The argument.

        #### Notes:
        - Arguments are bound by position in the order they are declared, and their count, types
          and `valid_values` are checked before the command's `run` function is called.
        - A list argument takes every remaining positional value, so it must be declared last.
        - For a list argument, `valid_values` may also be given as whole lists, such as
          `[["zsh", "bash"]]`. Their elements are what is accepted.
        """
        comptime assert conforms_to(T, ToValue), t"`T` must conform to `ToValue`. {reflect[T].name()} does not."
        comptime assert conforms_to(T, FromValue), t"`T` must conform to `FromValue`. {reflect[T].name()} does not."
        comptime assert reflect[T].base_name() != "Array", String(
            t"Positional `Array` arguments are not supported, since each argument binds one value. "
            t"Declare a `List` argument last to take the remaining values instead."
        )

        # A `List[E]` argument whose `valid_values` hold `E` names its elements directly. The
        # signature cannot spell "the element type of `T`", since conformances added through an
        # `__extension` give no access to associated types, so `E` is inferred from the values
        # and checked here instead.
        comptime is_element = reflect[T].base_name() == "List" and reflect[T].name() == String(
            "List[", reflect[E].name(), "]"
        )
        comptime assert reflect[E].name() == reflect[T].name() or is_element, String(
            t"`valid_values` must hold {reflect[T].name()}, or its elements when it is a list, "
            t"not {reflect[E].name()}."
        )
        comptime assert conforms_to(E, ToValue), String(
            t"The values in `valid_values` must conform to `ToValue`. {reflect[E].name()} does not."
        )
        comptime opt_type = OptType(reflect[T].name())

        # `bind` checks a list argument element by element, so a list's valid values are stored as
        # elements. Given as elements, each renders as one value. Given as whole lists, each is split
        # into its elements: stored whole, `[["zsh", "bash"]]` was one joined value that no single
        # element could ever match.
        var rendered = List[String]()
        for val in valid_values:
            var text = val.to_value()
            comptime if is_element:
                rendered.append(text^)
            else:
                if opt_type.is_list_type():
                    for element in text.split(LIST_SEPARATOR):
                        rendered.append(String(element))
                else:
                    rendered.append(text^)

        return Self(
            name=String(name),
            type=opt_type,
            usage=String(usage),
            required=required and not default,
            default=default^.and_then(_to_opt_string[T]),
            valid_values=rendered^,
            parse_check=_parse_check[T](),
        )
