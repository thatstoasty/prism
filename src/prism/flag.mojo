from collections import Optional, Dict
from prism._flag_set import Annotation

alias FlagActionFn = fn (ctx: Context, value: String) raises -> None
"""The type of a function that runs after a flag has been processed."""


@value
@register_passable("trivial")
struct FType():
    """Flag types enum helper."""
    alias String = "String"
    alias Bool = "Bool"
    alias Int = "Int"
    alias Int8 = "Int8"
    alias Int16 = "Int16"
    alias Int32 = "Int32"
    alias Int64 = "Int64"
    alias UInt = "UInt"
    alias UInt8 = "UInt8"
    alias UInt16 = "UInt16"
    alias UInt32 = "UInt32"
    alias UInt64 = "UInt64"
    alias Float16 = "Float16"
    alias Float32 = "Float32"
    alias Float64 = "Float64"
    alias StringList = "StringList"
    alias IntList = "IntList"
    alias Float64List = "Float64List"

    alias IntTypes = [
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
    alias FloatTypes = [Self.Float16, Self.Float32, Self.Float64]
    alias ListTypes = [Self.StringList, Self.IntList, Self.Float64List]
    alias ValidTypes = [
        Self.String,
        Self.Bool,
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
        Self.Float16,
        Self.Float32,
        Self.Float64,
        Self.StringList,
        Self.IntList,
        Self.Float64List,
    ]


# TODO: When we have trait objects, switch to using actual flag structs per type instead of
# needing to cast values to and from string.
@value
struct Flag(RepresentableCollectionElement, Stringable, Writable):
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
    var environment_variable: Optional[StringLiteral]
    """If no value is provided, will optionally check this environment variable for a value."""
    var file_path: Optional[StringLiteral]
    """If no value is provided, will optionally check read this file for a value. `environment_variable` takes precedence over this option."""
    var default: String
    """The default value of the flag."""
    var type: String
    """The type of the flag."""
    var annotations: Dict[String, List[String]]
    """The annotations of the flag which are used to determine grouping."""
    var action: Optional[FlagActionFn]
    """Function to run after the flag has been processed."""
    var changed: Bool
    """If the flag has been changed from its default value."""
    var required: Bool
    """If the flag is required."""
    var persistent: Bool
    """If the flag should persist to children commands."""

    fn __init__(
        mut self,
        name: String,
        type: String,
        *,
        shorthand: String = "",
        usage: String = "",
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
        default: String = "",
        required: Bool = False,
        persistent: Bool = False,
    ) -> None:
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
        self.annotations = Dict[String, List[String]]()
        self.action = action
        self.changed = False
        self.required = required
        self.persistent = persistent

    fn __str__(self) -> String:
        """Returns a string representation of the Flag.

        Returns:
            The string representation of the Flag.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Returns a string representation of the Flag.

        Returns:
            The string representation of the Flag.
        """
        return self.__str__()

    fn __eq__(self, other: Self) -> Bool:
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

    fn __ne__(self, other: Self) -> Bool:
        """Compares two Flags for inequality.

        Args:
            other: The other Flag to compare against.

        Returns:
            True if the Flags are not equal, False otherwise.
        """
        return not self == other

    fn write_to[W: Writer, //](self, mut writer: W):
        """Write Flag string representation to a writer.

        Parameters:
            W: The type of writer to write to.

        Args:
            writer: The formatter to write to.
        """

        @parameter
        fn write_optional(opt: Optional[String]):
            if opt:
                writer.write(repr(opt.value()))
            else:
                writer.write(repr(None))

        writer.write("Flag(name=", self.name)
        if self.shorthand != "":
            writer.write(", shorthand=", self.shorthand)
        writer.write(", Usage=", self.usage)
        if self.value:
            writer.write(", value=")
            write_optional(self.value)
        writer.write(
            ", default=",
            self.default,
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

    fn set(mut self, value: String) -> None:
        """Sets the value of the flag.

        Args:
            value: The value to set.
        """
        self.value = value
        self.changed = True

    fn get_with_transform[T: CollectionElement, //, transform: fn (value: String) -> T](self) -> T:
        """Returns the value of the flag with a transformation applied to it.

        Parameters:
            T: The type of the value to return.
            transform: The transformation to apply to the value.

        Returns:
            The transformed value of the flag.
        """
        if self.value:
            return transform(self.value.value())
        return transform(self.default)

    fn value_or_default(self) -> String:
        """Returns the value of the flag or the default value if it isn't set.

        Returns:
            The value of the flag or the default value.
        """
        return self.value.or_else(self.default)


fn string_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: String = "",
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `String` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="String",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn bool_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Bool = False,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Bool` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Bool",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Int",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int8_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int8 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int8` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Int8",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int16_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int16 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int16` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Int16",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int32_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int32 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int32` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Int32",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int64_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int64 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int64` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Int64",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt8 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="UInt",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint8_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt8 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt8` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="UInt8",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint16_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt16 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt16` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="UInt16",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint32_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt32 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt32` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="UInt32",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint64_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt64 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt64` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="UInt64",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float16_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Float16 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float16` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Float16",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float32_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Float32 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float32` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Float32",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float64_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Float64 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float64` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=String(default),
        type="Float64",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn string_list_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: List[String] = List[String](),
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `StringList` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=" ".join(default),
        type="StringList",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int_list_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: List[Int, True] = List[Int, True](),
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `IntList` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=" ".join(default),
        type="IntList",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float64_list_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: List[Float64, True] = List[Float64, True](),
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float64List` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=" ".join(default),
        type="Float64List",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )
