"""Flags, their types, and the annotations used to group them."""
from prism.opt_type import OptType
from prism._util import _to_opt_string
from prism.value import FromValue, ToValue, String, Bool, SIMD, List

comptime FlagActionFn = def (String) raises thin -> None
"""The type of a function that runs after a flag has been processed."""


# Flag Group annotations
@fieldwise_init
struct Annotation(ImplicitlyCopyable, Writable, Equatable, Hashable):
    """An annotation for a flag or a group of flags."""
    var value: UInt8
    """The value of the annotation."""

    # Individual flag annotations
    comptime REQUIRED = Self(0)
    """Annotation to mark a flag as required."""

    # Flag Group annotations
    comptime REQUIRED_AS_GROUP = Self(1)
    """Annotation to mark a group of flags as required as a group. All flags in the group must be set for it to be valid."""
    comptime ONE_REQUIRED = Self(2)
    """Annotation to mark a group of flags as required. At least one flag in the group must be set for it to be valid."""
    comptime MUTUALLY_EXCLUSIVE = Self(3)
    """Annotation to mark a group of flags as mutually exclusive. Only one flag in the group can be set for it to be valid."""

    def write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the annotation to a writer.

        Args:
            writer: The writer to write the annotation to.
        """
        if self == Self.REQUIRED:
            writer.write("REQUIRED")
        elif self == Self.REQUIRED_AS_GROUP:
            writer.write("REQUIRED_AS_GROUP")
        elif self == Self.ONE_REQUIRED:
            writer.write("ONE_REQUIRED")
        elif self == Self.MUTUALLY_EXCLUSIVE:
            writer.write("MUTUALLY_EXCLUSIVE")
        else:
            writer.write("unknown_annotation")


# TODO: When we have trait objects, switch to using actual flag structs per type instead of
# needing to cast values to and from string.
@fieldwise_init
struct Flag(Copyable, Writable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via `--name` or `-shorthand` and can have a value associated with them.
    """

    var name: String
    """The full name of the flag."""
    var shorthand: String
    """The shorthand of the flag."""
    var usage: String
    """The usage of the flag."""
    var value: Optional[String]
    """The value of the flag."""
    var environment_variable: Optional[String]
    """If no value is provided, will optionally check this environment variable for a value."""
    var file_path: Optional[String]
    """If no value is provided, will optionally check read this file for a value. `environment_variable` takes precedence over this option."""
    var default: Optional[String]
    """The default value of the flag."""
    var type: OptType
    """The type of the flag."""
    var annotations: Dict[Annotation, List[String]]
    """The annotations of the flag which are used to determine grouping."""
    var action: Optional[FlagActionFn]
    """Function to run after the flag has been processed."""
    var changed: Bool
    """If the flag has been changed from its default value."""
    var required: Bool
    """If the flag is required."""
    var persistent: Bool
    """If the flag should persist to children commands."""

    def __init__(
        out self,
        name: String,
        type: OptType,
        *,
        shorthand: String = "",
        usage: String = "",
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        default: Optional[String] = None,
        required: Bool = False,
        persistent: Bool = False,
    ):
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            type: The type of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            default: The default value of the flag.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage
        self.value = None
        self.environment_variable = environment_variable
        self.file_path = file_path
        self.default = default
        self.type = type
        self.annotations = Dict[Annotation, List[String]]()
        self.action = action
        self.changed = False
        self.required = required
        self.persistent = persistent

    def __eq__(self, other: Self) -> Bool:
        """Compares two Flags for equality.

        Args:
            other: The other Flag to compare against.

        Returns:
            True if the Flags are equal, False otherwise.
        """
        return (
            self.name == other.name
            and self.shorthand == other.shorthand
            and self.usage == other.usage
            and self.value == other.value
            and self.default == other.default
            and self.type == other.type
            and self.changed == other.changed
        )

    def write_to(self, mut writer: Some[Writer]):
        """Write string representation to a writer.

        Args:
            writer: The formatter to write to.
        """
        writer.write("Flag(name=", self.name)
        if self.shorthand != "":
            writer.write(", shorthand=", self.shorthand)
        writer.write(
            ", usage=", self.usage, ", value=", self.value, ", default=", self.default,
            ", type=",
            self.type,
            ", changed=",
            self.changed,
            ", required=",
            self.required,
            ", persistent=",
            self.persistent,
            ")",
        )

    def set(mut self, value: ImmStringSpan) -> None:
        """Sets the value of the flag.

        Args:
            value: The value to set.
        """
        self.value = String(value)
        self.changed = True

    def get_with_transform[
        T: ImplicitlyCopyable, //, transform: def (value: StringSpan) thin -> T
    ](self) -> Optional[T]:
        """Returns the value of the flag with a transformation applied to it.

        Parameters:
            T: The type of the value to return.
            transform: The transformation to apply to the value.

        Returns:
            The transformed value of the flag.
        """
        if self.value:
            return transform(self.value.value())
        elif self.default:
            return transform(self.default.value())

        return None

    def value_or_default(self) -> Optional[String]:
        """Returns the value of the flag or the default value if it isn't set.

        Returns:
            The value of the flag or the default value.
        """
        if self.value:
            return self.value.value()
        elif self.default:
            return self.default.value()

        return None

    def names(self) -> List[String]:
        """Returns the names of the flag.

        Returns:
            The names of the flag.
        """
        var names: List[String] = [self.name, self.shorthand]
        # TODO: Add aliases to list when flags support them.
        return names^

    @staticmethod
    def new[T: AnyType](
        name: ImmStringSpan,
        usage: ImmStringSpan,
        *,
        shorthand: ImmStringSpan = "",
        var default: Optional[T] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Self:
        """Constructs a flag holding a `T`.

        Parameters:
            T: The type of value the flag holds. Must conform to `ToValue`, and to `FromValue` to
                be read back with `FlagSet.get`.

        Args:
            name: The name of the flag, matched as `--name`.
            usage: What the flag is for. Shown in help output.
            shorthand: A single character alias, matched as `-s`.
            default: The value to use when the flag is not passed. Supplying one makes the flag
                optional even if `required` is True.
            environment_variable: An environment variable to read the value from when the flag is
                not passed.
            file_path: A file to read the value from when the flag is not passed and the
                environment variable is unset.
            action: A function to run once the flag has been parsed.
            required: Whether the flag must be passed.
            persistent: Whether child commands inherit the flag.

        Returns:
            The flag.

        #### Notes:
        - `T` determines the flag's `OptType`, which is what tells the parser whether the flag takes
          a following value. A `Bool` flag consumes nothing, so `--verbose` stands alone.
        """
        comptime assert conforms_to(T, ToValue), String(t"`T` must conform to `ToValue`. {reflect[T].name()} does not.")
        comptime opt_type = OptType(reflect[T].name())
        return Self(
            name=String(name),
            shorthand=String(shorthand),
            usage=String(usage),
            type=opt_type,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required and not default,
            persistent=persistent,
            default=default^.and_then(_to_opt_string[T]),
        )
