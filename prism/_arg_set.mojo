"""The set of positional arguments a command received."""
from std.collections.list import _ListIter

from prism._util import string_to_bool
from prism.arg import Arg
from prism.from_flag_value import FromFlagValue
from prism.opt_type import OptType


def _validate_value(type: OptType, name: ImmStringSpan, value: ImmStringSpan) raises -> None:
    """Checks that an argument's text parses as its declared type.

    Args:
        type: The declared type.
        name: The argument's name, for the error message.
        value: The text bound to the argument.

    Raises:
        Error: If the text does not parse as the declared type.

    #### Notes:
    - This runs before the command's `run` function, so a mistyped argument is reported instead of
      surfacing later as a failure inside `get`.
    """
    if type == OptType.String:
        return

    try:
        if type == OptType.Bool:
            _ = string_to_bool(String(value))
        elif type.is_int_type():
            _ = atol(value)
        elif type.is_float_type():
            _ = atof(value)
    except e:
        raise Error(t"Invalid value for argument `{name}`: {e}")


struct ArgSet(Boolable, Copyable, Sized, Writable, Iterable):
    """The positional arguments a command received.

    Values can be read positionally, as before, or by the name of a declared `Arg`:

    ```mojo
    var target = args.get[String]("target")
    var first = args[0]
    ```
    """

    comptime Element = String
    comptime IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[mut=iterable_mut]
    ]: Iterator = _ListIter[String, iterable_origin, True]

    var args: List[Arg]
    """The declared arguments, each bound to a value where one was supplied."""
    var values: List[String]
    """Every positional value the command received, in order."""

    def __init__(out self, var args: List[Arg] = [], var values: List[String] = []):
        """Constructs an argument set.

        Args:
            args: The arguments the command declares.
            values: The positional values the command received.
        """
        self.args = args^
        self.values = values^

    @always_inline
    def __bool__(self) -> Bool:
        return Bool(self.values)

    @always_inline
    def __len__(self) -> Int:
        return len(self.values)

    @__unsafe_nested_origins_read_only
    @always_inline
    def __getitem__(
        ref self, idx: Int, /
    ) -> ref[self.values.unsafe_get(index(idx))] String:
        """Returns the positional value at `index`.

        Args:
            idx: The position to read.

        Returns:
            A copy of the value at that position.
        """
        return self.values.unsafe_get(idx)

    def __iter__(ref self) -> Self.IteratorType[origin_of(self)]:
        return rebind[Self.IteratorType[origin_of(self)]](iter(self.values))

    def write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the argument set to a writer.

        Args:
            writer: The writer to write to.
        """
        writer.write(self.values)

    def lookup(ref self, name: ImmStringSpan) -> Optional[Pointer[Arg, origin_of(self.args)]]:
        """Returns a pointer to the declared argument with the given name.

        Args:
            name: The name of the argument.

        Returns:
            A pointer to the argument, or `None` when no argument of that name is declared.
        """
        for ref arg in self.args:
            if arg.name == name:
                return Pointer(to=arg)

        return None

    def get[T: AnyType](self, name: ImmStringSpan) raises -> Optional[T]:
        """Returns the value of a declared argument as a `T`.

        Parameters:
            T: The type to read the argument as. Must conform to `FromFlagValue`.

        Args:
            name: The name of the argument.

        Returns:
            The argument's value as a `T`, or `None` if no argument of that name is declared, or it
            was omitted and has no default.

        Raises:
            Error: If the argument's value cannot be read as a `T`.
        """
        comptime assert conforms_to(T, FromFlagValue), String(
            reflect[T].name(),
            " does not conform to `FromFlagValue`.",
        )

        var arg = self.lookup(name)
        if not arg:
            return None

        var result = arg.value()[].value_or_default()
        if not result:
            return None

        return T(result.value())

    def bind(mut self, var values: List[String]) raises -> None:
        """Binds positional values to the declared arguments and validates them.

        Args:
            values: The positional values the command received.

        Raises:
            Error: If a required argument is missing, an unexpected argument was supplied, or a
                value does not parse as its declared type.

        #### Notes:
        - A command that declares no arguments accepts any number of them, which is what leaves
          `arg_validator` in charge for commands that do their own checking.
        """
        for i in range(len(self.args)):
            if i < len(values):
                self.args[i].value = values[i]

        self.values = values^
        if not self.args:
            return

        var required = 0
        for arg in self.args:
            if arg.required:
                required += 1

        if len(self.values) < required:
            raise Error(
                t"Missing required argument: `{self.args[len(self.values)].name}`. "
                t"Expected {required} argument(s), received {len(self.values)}."
            )

        if len(self.values) > len(self.args):
            raise Error(
                t"Unexpected argument: `{self.values[len(self.args)]}`. "
                t"This command accepts at most {len(self.args)} argument(s), received {len(self.values)}."
            )

        for arg in self.args:
            if not arg.value:
                continue

            _validate_value(arg.type, arg.name, arg.value.value())

            # An argument that names the values it accepts rejects anything else, and says what it
            # would have taken instead.
            if arg.valid_values and arg.value.value() not in arg.valid_values:
                raise Error(
                    t"Invalid value for argument `{arg.name}`: `{arg.value.value()}`. "
                    t"Valid values are: {', '.join(arg.valid_values)}."
                )

    def usage(self) -> String:
        """Renders the declared arguments for a usage line, such as `TARGET [REPLICAS]`.

        Returns:
            The rendered arguments, or an empty string when none are declared.
        """
        var builder = String(capacity=128)
        for i in range(len(self.args)):
            if i > 0:
                builder.write(" ")

            var name = self.args[i].name.upper()
            if self.args[i].required:
                builder.write(name)
            else:
                builder.write("[", name, "]")

        return builder^
